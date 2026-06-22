package config

import (
	"net/url"
	"strings"
	"testing"
)

func TestLoadDatabaseURL_prefersPostgresOverStaleDatabaseURL(t *testing.T) {
	t.Setenv("DATABASE_URL", "postgres://personalos:wrongpass@personal-os-pg:5432/personalos?sslmode=disable")
	t.Setenv("POSTGRES_DATABASE_HOST", "personal-os-pg")
	t.Setenv("POSTGRES_DATABASE_PORT", "5432")
	t.Setenv("POSTGRES_DATABASE_NAME", "personalos")
	t.Setenv("POSTGRES_DATABASE_USER", "personalos")
	t.Setenv("POSTGRES_DATABASE_PASSWORD", "correct-pass")

	got := loadDatabaseURL()
	parsed, err := url.Parse(got)
	if err != nil {
		t.Fatalf("parse database url: %v\nurl=%q", err, got)
	}
	pass, ok := parsed.User.Password()
	if !ok {
		t.Fatal("expected password in url")
	}
	if pass != "correct-pass" {
		t.Fatalf("password = %q, want %q", pass, "correct-pass")
	}
}

func TestLoadDatabaseURL_stripsCarriageReturnFromPassword(t *testing.T) {
	t.Setenv("DATABASE_URL", "")
	t.Setenv("POSTGRES_DATABASE_HOST", "personal-os-pg")
	t.Setenv("POSTGRES_DATABASE_PORT", "5432")
	t.Setenv("POSTGRES_DATABASE_NAME", "personalos")
	t.Setenv("POSTGRES_DATABASE_USER", "personalos")
	t.Setenv("POSTGRES_DATABASE_PASSWORD", "$332003Phuc\r")

	got := loadDatabaseURL()
	parsed, err := url.Parse(got)
	if err != nil {
		t.Fatalf("parse database url: %v\nurl=%q", err, got)
	}
	pass, ok := parsed.User.Password()
	if !ok {
		t.Fatal("expected password in url")
	}
	if pass != "$332003Phuc" {
		t.Fatalf("password = %q, want %q", pass, "$332003Phuc")
	}
}

func TestLoadDatabaseURL_quotedPasswordWithDollar(t *testing.T) {
	t.Setenv("DATABASE_URL", "")
	t.Setenv("POSTGRES_DATABASE_HOST", "personal-os-pg")
	t.Setenv("POSTGRES_DATABASE_PORT", "5432")
	t.Setenv("POSTGRES_DATABASE_NAME", "personalos")
	t.Setenv("POSTGRES_DATABASE_USER", "personalos")
	t.Setenv("POSTGRES_DATABASE_PASSWORD", `"$332003Phuc"`)

	got := loadDatabaseURL()
	parsed, err := url.Parse(got)
	if err != nil {
		t.Fatalf("parse database url: %v\nurl=%q", err, got)
	}
	pass, ok := parsed.User.Password()
	if !ok {
		t.Fatal("expected password in url")
	}
	if pass != "$332003Phuc" {
		t.Fatalf("password = %q, want %q", pass, "$332003Phuc")
	}
	if !strings.Contains(got, "personal-os-pg:5432") {
		t.Fatalf("host missing from url: %q", got)
	}
}
