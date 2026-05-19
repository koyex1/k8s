from fastapi import FastAPI, Header, HTTPException
from models import OrderRequest
from db import conn
from redis_client import redis_client
from logger import logger
from rabbitmq_publisher import publish_order_created_rabbitmq
from kafka_publisher import publish_order_created_kafka
import json

app = FastAPI()

SERVICE_NAME = "order-service"

@app.post("/order")
def create_order(
    order: OrderRequest,
    x_user_id: str = Header(None),
    x_username: str = Header(None)
):

    if not x_user_id or not x_username:
        raise HTTPException(
            status_code=401,
            detail="missing authentication headers"
        )

    logger.info({
        "service": SERVICE_NAME,
        "operation": "create_order",
        "user_id": x_user_id,
        "username": x_username,
        "product_id": order.product_id
    })

    cursor = conn.cursor()

    cursor.execute(
        """
        INSERT INTO orders(
            user_id,
            username,
            product_id,
            quantity
        )
        VALUES(%s, %s, %s, %s)
        RETURNING id
        """,
        (
            x_user_id,
            x_username,
            order.product_id,
            order.quantity
        )
    )

    order_id = cursor.fetchone()[0]

    order_data = {
        "id": order_id,
        "user_id": x_user_id,
        "username": x_username,
        "product_id": order.product_id,
        "quantity": order.quantity,
        "status": "pending"
    }

    redis_client.set(
        f"order:{order_id}",
        json.dumps(order_data)
    )

    publish_order_created_rabbitmq(order_data)
    publish_order_created_kafka(order_data)

    logger.info({
        "service": SERVICE_NAME,
        "operation": "publish_order_created",
        "order_id": order_id
    })

    return {
        "message": "order created",
        "order": order_data
    }