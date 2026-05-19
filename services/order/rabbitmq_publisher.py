import pika
import os
import json

def publish_order_created_rabbitmq(order_data):

    credentials = pika.PlainCredentials(
        os.getenv("RABBITMQ_DEFAULT_USER"),
        os.getenv("RABBITMQ_DEFAULT_PASS"),
    )

    connection = pika.BlockingConnection(
        pika.ConnectionParameters(
            host=os.getenv("RABBITMQ_HOST"),
            credentials=credentials,
        )
    )

    channel = connection.channel()

    channel.basic_publish(
        exchange="orders.exchange",
        routing_key="orders.created",
        body=json.dumps(order_data),
    )

    connection.close()