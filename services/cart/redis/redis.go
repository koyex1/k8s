package redisclient

import (
	"context"
	"os"
	"strings"

	"github.com/redis/go-redis/v9"

	"cart/logger"
)

var Ctx = context.Background()

var Client *redis.Client

func Connect() {

	Client = redis.NewClient(&redis.Options{
		Addr: strings.TrimPrefix(os.Getenv("REDIS_URL"), "redis://"),
	})

	_, err := Client.Ping(Ctx).Result()

	if err != nil {

		logger.Log.Error().
			Err(err).
			Msg("failed to connect redis")

		panic(err)
	}

	logger.Log.Info().
		Msg("redis connected")
}
