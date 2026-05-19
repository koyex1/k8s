package main

import (
	"cart/controller"
	"cart/logger"
	"cart/middleware"
	"cart/postgres"
	redisclient "cart/redis"

	"github.com/gin-gonic/gin"
)

func main() {

	logger.Init()

	err := postgres.Connect()

	if err != nil {
		panic(err)
	}

	redisclient.Connect()

	r := gin.Default()

	r.Use(middleware.RequestLogger())

	r.POST("/cart", controller.AddCart)
	r.GET("/cart", controller.ListCarts)
	r.DELETE("/cart/:id", controller.DeleteCart)

	logger.Log.Info().
		Msg("cart service started on :8080")

	r.Run(":8080")
}