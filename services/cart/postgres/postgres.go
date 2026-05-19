package postgres

import (
	"context"
	"fmt"
	"os"

	"github.com/jackc/pgx/v5/pgxpool"

	"cart/logger"
)

var DB *pgxpool.Pool

func Connect() error {

	host := os.Getenv("DB_HOST")
	port := os.Getenv("DB_PORT")
	name := os.Getenv("DB_NAME")
	user := os.Getenv("DB_USER")
	pass := os.Getenv("DB_PASSWORD")

	conn := fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s",
		user,
		pass,
		host,
		port,
		name,
	)

	db, err := pgxpool.New(context.Background(), conn)

	if err != nil {

		logger.Log.Error().
			Err(err).
			Msg("failed to connect postgres")

		return err
	}

	DB = db

	logger.Log.Info().
		Msg("postgres connected")

	return nil
}