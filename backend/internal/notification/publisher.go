package notification

import (
	"context"
	"log"
	"strings"
	"time"

	"github.com/personal-os/backend/pkg/config"
	"github.com/segmentio/kafka-go"
)

type Publisher struct {
	writer  *kafka.Writer
	topic   string
	enabled bool
}

func NewPublisher(cfg config.NotificationConfig) *Publisher {
	if !cfg.Enabled || len(cfg.KafkaBrokers) == 0 {
		log.Printf("notification: Kafka disabled — logs only (set KAFKA_BROKERS + KAFKA_NOTIFICATION_TOPIC)")
		return &Publisher{enabled: false}
	}
	w := &kafka.Writer{
		Addr:         kafka.TCP(cfg.KafkaBrokers...),
		Topic:        cfg.KafkaTopic,
		Balancer:     &kafka.LeastBytes{},
		RequiredAcks: kafka.RequireOne,
		Async:        false,
	}
	log.Printf("notification: Kafka publisher enabled topic=%s brokers=%s", cfg.KafkaTopic, strings.Join(cfg.KafkaBrokers, ","))
	return &Publisher{writer: w, topic: cfg.KafkaTopic, enabled: true}
}

func (p *Publisher) Enabled() bool {
	return p != nil && p.enabled
}

func (p *Publisher) Publish(ctx context.Context, event RequestedEvent) error {
	if !p.Enabled() {
		return nil
	}
	payload, err := event.JSON()
	if err != nil {
		return err
	}
	return p.writer.WriteMessages(ctx, kafka.Message{
		Key:   []byte(event.EventID),
		Value: payload,
		Time:  time.Now().UTC(),
	})
}

func (p *Publisher) Close() error {
	if p == nil || p.writer == nil {
		return nil
	}
	return p.writer.Close()
}
