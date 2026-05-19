import os
import json
from kafka import KafkaProducer

# -----------------------------
# Create Kafka Producer client
# -----------------------------
producer = KafkaProducer(
    # Kafka broker list (same as bootstrap servers)
    bootstrap_servers=[
        os.getenv("KAFKA_BROKER_1", "kafka1:29092"),
        os.getenv("KAFKA_BROKER_2", "kafka2:29093"),
    ],

    # Convert Python dict → JSON bytes
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),

    # Ensures stronger delivery guarantees
    acks="all",  # wait for all in-sync replicas
    retries=3
)

# -----------------------------
# Publish function (equivalent to RabbitMQ publish)
# -----------------------------
def publish_order_created_kafka(order_data: dict):

    # Send message to Kafka topic
    producer.send(
        topic="orders.created",   # Kafka topic (like exchange+queue in RabbitMQ)
        value=order_data          # message payload
    )

    # Ensure message is flushed (important for reliability)
    producer.flush()