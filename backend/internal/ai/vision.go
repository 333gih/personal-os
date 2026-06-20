package ai

import (
	"context"
	"encoding/base64"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/sashabaranov/go-openai"
)

// ChatVisionJSON sends a multimodal prompt (text + image) and returns raw assistant text.
func (s *Service) ChatVisionJSON(userID uuid.UUID, endpoint, systemPrompt, userText, imageMIME string, imageData []byte) (string, error) {
	if !s.Configured() {
		return "", fmt.Errorf("ai not configured")
	}
	if len(imageData) == 0 {
		return "", fmt.Errorf("image required for vision request")
	}
	if imageMIME == "" {
		imageMIME = "image/png"
	}
	model := s.visionModel
	if model == "" {
		model = s.chatModel
	}

	dataURL := fmt.Sprintf("data:%s;base64,%s", imageMIME, base64.StdEncoding.EncodeToString(imageData))
	start := time.Now()
	resp, err := s.client.CreateChatCompletion(context.Background(), openai.ChatCompletionRequest{
		Model: model,
		Messages: []openai.ChatCompletionMessage{
			{Role: openai.ChatMessageRoleSystem, Content: systemPrompt},
			{
				Role: openai.ChatMessageRoleUser,
				MultiContent: []openai.ChatMessagePart{
					{Type: openai.ChatMessagePartTypeText, Text: userText},
					{
						Type: openai.ChatMessagePartTypeImageURL,
						ImageURL: &openai.ChatMessageImageURL{
							URL: dataURL,
						},
					},
				},
			},
		},
		Temperature: 0.2,
	})
	latency := int(time.Since(start).Milliseconds())
	if err != nil {
		return "", err
	}
	if len(resp.Choices) == 0 {
		return "", fmt.Errorf("empty response")
	}
	if userID != uuid.Nil {
		s.logInteraction(userID, endpoint, model, resp.Usage.PromptTokens, resp.Usage.CompletionTokens, latency)
	}
	return strings.TrimSpace(resp.Choices[0].Message.Content), nil
}
