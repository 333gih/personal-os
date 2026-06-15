package auth

import (
	"errors"
	"fmt"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

type fashClaims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

func parseFashToken(tokenStr, secret, issuer string) (uuid.UUID, string, error) {
	secret = strings.TrimSpace(secret)
	if secret == "" {
		return uuid.Nil, "", errors.New("fash auth jwt secret not configured")
	}

	token, err := jwt.ParseWithClaims(tokenStr, &fashClaims{}, func(t *jwt.Token) (any, error) {
		if t.Method != jwt.SigningMethodHS256 {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return []byte(secret), nil
	})
	if err != nil {
		return uuid.Nil, "", err
	}

	claims, ok := token.Claims.(*fashClaims)
	if !ok || !token.Valid {
		return uuid.Nil, "", errors.New("invalid token")
	}

	if issuer != "" && claims.Issuer != issuer {
		return uuid.Nil, "", fmt.Errorf("invalid token issuer")
	}

	userIDStr := strings.TrimSpace(claims.UserID)
	if userIDStr == "" {
		userIDStr = strings.TrimSpace(claims.Subject)
	}
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return uuid.Nil, "", fmt.Errorf("invalid user id in token")
	}

	return userID, strings.TrimSpace(claims.Email), nil
}
