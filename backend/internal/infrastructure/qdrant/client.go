package qdrant

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/google/uuid"
)

type Client struct {
	baseURL    string
	apiKey     string
	collection string
	vectorSize int
	http       *http.Client
	enabled    bool
}

type PointPayload struct {
	UserID      string   `json:"userId"`
	EntityType  string   `json:"entityType"`
	EntityID    string   `json:"entityId"`
	SourceTable string   `json:"sourceTable"`
	Tags        []string `json:"tags,omitempty"`
	Title       string   `json:"title,omitempty"`
	CreatedAt   string   `json:"createdAt"`
}

type SearchHit struct {
	ID      string
	Score   float64
	Payload PointPayload
}

func NewClient(baseURL, apiKey, collection string, vectorSize int, enabled bool) *Client {
	return &Client{
		baseURL:    strings.TrimSuffix(baseURL, "/"),
		apiKey:     apiKey,
		collection: collection,
		vectorSize: vectorSize,
		enabled:    enabled,
		http:       &http.Client{Timeout: 30 * time.Second},
	}
}

func (c *Client) Enabled() bool {
	return c != nil && c.enabled
}

func (c *Client) EnsureCollection(ctx context.Context) error {
	if !c.Enabled() {
		return nil
	}
	body := map[string]any{
		"vectors": map[string]any{
			"size":     c.vectorSize,
			"distance": "Cosine",
		},
	}
	return c.do(ctx, http.MethodPut, "/collections/"+c.collection, body, nil)
}

func (c *Client) Upsert(ctx context.Context, id uuid.UUID, vector []float32, payload PointPayload) error {
	if !c.Enabled() {
		return nil
	}
	body := map[string]any{
		"points": []map[string]any{
			{
				"id":      id.String(),
				"vector":  vector,
				"payload": payload,
			},
		},
	}
	return c.do(ctx, http.MethodPut, "/collections/"+c.collection+"/points?wait=true", body, nil)
}

func (c *Client) Delete(ctx context.Context, id uuid.UUID) error {
	if !c.Enabled() {
		return nil
	}
	body := map[string]any{
		"points": []string{id.String()},
	}
	return c.do(ctx, http.MethodPost, "/collections/"+c.collection+"/points/delete?wait=true", body, nil)
}

func (c *Client) Search(ctx context.Context, userID uuid.UUID, vector []float32, limit int) ([]SearchHit, error) {
	if !c.Enabled() {
		return nil, fmt.Errorf("qdrant disabled")
	}
	if limit <= 0 || limit > 50 {
		limit = 20
	}
	body := map[string]any{
		"vector":       vector,
		"limit":        limit,
		"with_payload": true,
		"filter": map[string]any{
			"must": []map[string]any{
				{
					"key": "userId",
					"match": map[string]any{
						"value": userID.String(),
					},
				},
			},
		},
	}
	var resp struct {
		Result []struct {
			ID      json.RawMessage `json:"id"`
			Score   float64         `json:"score"`
			Payload PointPayload    `json:"payload"`
		} `json:"result"`
	}
	if err := c.do(ctx, http.MethodPost, "/collections/"+c.collection+"/points/search", body, &resp); err != nil {
		return nil, err
	}
	hits := make([]SearchHit, 0, len(resp.Result))
	for _, r := range resp.Result {
		id := strings.Trim(string(r.ID), `"`)
		hits = append(hits, SearchHit{ID: id, Score: r.Score, Payload: r.Payload})
	}
	return hits, nil
}

func (c *Client) do(ctx context.Context, method, path string, body any, out any) error {
	var reader io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return err
		}
		reader = bytes.NewReader(b)
	}
	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, reader)
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	if c.apiKey != "" {
		req.Header.Set("api-key", c.apiKey)
	}
	res, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer res.Body.Close()
	data, err := io.ReadAll(res.Body)
	if err != nil {
		return err
	}
	if res.StatusCode >= 400 {
		if res.StatusCode == http.StatusConflict || res.StatusCode == http.StatusBadRequest {
			// Collection already exists — treat as success for EnsureCollection
			if strings.Contains(string(data), "already exists") {
				return nil
			}
		}
		return fmt.Errorf("qdrant %s %s: %s", method, path, strings.TrimSpace(string(data)))
	}
	if out != nil && len(data) > 0 {
		if err := json.Unmarshal(data, out); err != nil {
			return err
		}
	}
	return nil
}
