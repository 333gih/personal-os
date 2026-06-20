package ai

import "testing"

func TestParseJSONResponse(t *testing.T) {
	var result AnalyzeResult
	raw := "```json\n{\"summary\":\"Hello world\",\"tags\":[\"note\"]}\n```"
	if err := parseJSONResponse(raw, &result); err != nil {
		t.Fatalf("parse fenced json: %v", err)
	}
	if result.Summary != "Hello world" {
		t.Fatalf("summary = %q", result.Summary)
	}
	if len(result.Tags) != 1 || result.Tags[0] != "note" {
		t.Fatalf("tags = %#v", result.Tags)
	}
}

func TestParseJSONResponseWithPrefix(t *testing.T) {
	var result AnalyzeResult
	raw := "Here is the result:\n{\"classification\":\"learning\",\"suggested_type\":\"learning_course\"}"
	if err := parseJSONResponse(raw, &result); err != nil {
		t.Fatalf("parse prefixed json: %v", err)
	}
	if result.Classification != "learning" {
		t.Fatalf("classification = %q", result.Classification)
	}
}
