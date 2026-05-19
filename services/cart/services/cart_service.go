package services

import (
	"context"
	"encoding/json"
	"fmt"

	"cart/logger"
	"cart/models"
	"cart/postgres"
	redisclient "cart/redis"
)

func AddCart(cart models.Cart) error {

	err := postgres.DB.QueryRow(
		context.Background(),
		`
		INSERT INTO cart(product_id, quantity)
		VALUES($1, $2)
		RETURNING id
		`,
		cart.ProductID,
		cart.Quantity,
	).Scan(&cart.ID)

	if err != nil {

		logger.Log.Error().
			Err(err).
			Str("operation", "db_insert_cart").
			Msg("failed to insert cart")

		return err
	}

	data, _ := json.Marshal(cart)

	redisclient.Client.Set(
		redisclient.Ctx,
		"cart:"+fmt.Sprint(cart.ID),
		data,
		0,
	)

	logger.Log.Info().
		Str("operation", "add_cart").
		Str("cart_id", fmt.Sprint(cart.ID)).
		Msg("cart added successfully")

	return nil
}

func ListCarts() ([]models.Cart, error) {

	keys, _ := redisclient.Client.Keys(
		redisclient.Ctx,
		"cart:*",
	).Result()

	carts := make([]models.Cart, 0)

	if len(keys) > 0 {

		logger.Log.Info().
			Str("operation", "list_carts").
			Msg("cache hit")

		for _, key := range keys {

			val, err := redisclient.Client.Get(
				redisclient.Ctx,
				key,
			).Result()

			if err != nil {
				continue
			}

			var cart models.Cart

			err = json.Unmarshal([]byte(val), &cart)

			if err != nil {
				continue
			}

			carts = append(carts, cart)
		}

		return carts, nil
	}

	logger.Log.Info().
		Str("operation", "list_carts").
		Msg("cache miss")

	rows, err := postgres.DB.Query(
		context.Background(),
		`
		SELECT
			cart.id,
			cart.quantity,
			products.id,
			products.name
		FROM cart
		JOIN products
		ON cart.product_id = products.id
		`,
	)

	if err != nil {

		logger.Log.Error().
			Err(err).
			Msg("failed to fetch carts")

		return nil, err
	}

	defer rows.Close()

	for rows.Next() {

		var cart models.Cart
		var id int

		err := rows.Scan(
			&id,
			&cart.Quantity,
			&cart.ProductID,
			&cart.ProductName,
		)

		if err != nil {

			logger.Log.Error().
				Err(err).
				Msg("failed to scan cart row")

			continue
		}

		cart.ID = fmt.Sprint(id)

		carts = append(carts, cart)

		data, _ := json.Marshal(cart)

		redisclient.Client.Set(
			redisclient.Ctx,
			"cart:"+cart.ID,
			data,
			0,
		)
	}

	return carts, nil
}

func DeleteCart(id string) error {

	_, err := postgres.DB.Exec(
		context.Background(),
		"DELETE FROM cart WHERE id=$1",
		id,
	)

	if err != nil {

		logger.Log.Error().
			Err(err).
			Str("cart_id", id).
			Msg("failed to delete cart")

		return err
	}

	redisclient.Client.Del(
		redisclient.Ctx,
		"cart:"+id,
	)

	logger.Log.Info().
		Str("operation", "delete_cart").
		Str("cart_id", id).
		Msg("cart deleted")

	return nil
}
