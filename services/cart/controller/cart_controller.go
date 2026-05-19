package controller

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"cart/logger"
	"cart/models"
	"cart/services"
)

func AddCart(c *gin.Context) {

	userId := c.GetHeader("X-User-Id")
	username := c.GetHeader("X-Username")

	if userId == "" || username == "" {

		logger.Log.Warn().
			Str("operation", "add_cart").
			Msg("missing auth headers")

		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "missing auth headers",
		})

		return
	}

	var cart models.Cart

	if err := c.ShouldBindJSON(&cart); err != nil {

		logger.Log.Error().
			Err(err).
			Msg("invalid request payload")

		c.JSON(http.StatusBadRequest, gin.H{
			"error": err.Error(),
		})

		return
	}

	logger.Log.Info().
		Str("operation", "add_cart").
		Str("user_id", userId).
		Str("username", username).
		Int("product_id", cart.ProductID).
		Int("quantity", cart.Quantity).
		Msg("incoming add cart request")

	err := services.AddCart(cart)

	if err != nil {

		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})

		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "cart added",
	})
}

func ListCarts(c *gin.Context) {

	userId := c.GetHeader("X-User-Id")
	username := c.GetHeader("X-Username")

	if userId == "" || username == "" {

		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "missing auth headers",
		})

		return
	}

	carts, err := services.ListCarts()

	if err != nil {

		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})

		return
	}

	logger.Log.Info().
		Str("operation", "list_carts").
		Str("user_id", userId).
		Str("username", username).
		Msg("list carts request")

	c.JSON(http.StatusOK, carts)
}

func DeleteCart(c *gin.Context) {

	userId := c.GetHeader("X-User-Id")
	username := c.GetHeader("X-Username")

	if userId == "" || username == "" {

		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "missing auth headers",
		})

		return
	}

	id := c.Param("id")

	logger.Log.Info().
		Str("operation", "delete_cart").
		Str("user_id", userId).
		Str("username", username).
		Str("cart_id", id).
		Msg("delete cart request")

	err := services.DeleteCart(id)

	if err != nil {

		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})

		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "cart deleted",
	})
}