const { Kafka } = require("kafkajs");

const pool = require("./db");
const logger = require("./logger");

async function startKafkaConsumer() {

  // ---------------------------------------
  // 1. Create Kafka client (cluster connection)
  // ---------------------------------------
  const kafka = new Kafka({
    clientId: "notification-service",
    brokers: [
      process.env.KAFKA_BROKER_1 || "kafka:29092",
      process.env.KAFKA_BROKER_2 || "kafka:29093",
    ],
  });

  // ---------------------------------------
  // 2. Create consumer group
  // ---------------------------------------
  const consumer = kafka.consumer({
    groupId: "notification-service-group",
  });

  // ---------------------------------------
  // 3. Connect to Kafka cluster
  // ---------------------------------------
  await consumer.connect();

  logger.info({
    service: "notification-service",
    operation: "kafka_connected",
    topic: "orders.created",
    group_id: "notification-service-group"
  });

  // ---------------------------------------
  // 4. Subscribe to topic (equivalent of queue)
  // ---------------------------------------
  await consumer.subscribe({
    topic: "orders.created",
    fromBeginning: false, // only new messages
  });

  // ---------------------------------------
  // 5. Start consuming messages
  // ---------------------------------------
  await consumer.run({

    eachMessage: async ({ topic, partition, message }) => {

      try {

        // ---------------------------------------
        // 6. Parse Kafka message
        // ---------------------------------------
        const data = JSON.parse(
          message.value.toString()
        );

        logger.info({
          service: "notification-service",
          operation: "message_received",
          topic,
          partition,
          offset: message.offset,
          user_id: data.user_id,
          username: data.username,
          order_id: data.order_id
        });

        logger.info({
          service: "notification-service",
          operation: "processing_delay_started",
          delay_seconds: 10
        });

        // ---------------------------------------
        // 7. Simulated processing delay
        // ---------------------------------------
        await new Promise(
          (resolve) => setTimeout(resolve, 10000)
        );

        const notificationMessage =
          `Hello ${data.username}, your order has been processed successfully via Kafka`;

        // ---------------------------------------
        // 8. Save notification to DB
        // ---------------------------------------
        await pool.query(
          `
          INSERT INTO notifications(
            user_id,
            username,
            message
          )
          VALUES($1, $2, $3)
          `,
          [
            data.user_id,
            data.username,
            notificationMessage
          ]
        );

        logger.info({
          service: "notification-service",
          operation: "notification_saved",
          user_id: data.user_id
        });

        // ---------------------------------------
        // 9. SSE real-time push
        // ---------------------------------------
        const client =
          global.sseClients.get(String(data.user_id));

        if (client) {

          client.write(
            `data: ${JSON.stringify({
              type: "order_processed",
              order_id: data.order_id,
              message: notificationMessage
            })}\n\n`
          );

          logger.info({
            service: "notification-service",
            operation: "sse_notification_sent",
            user_id: data.user_id
          });

        } else {

          logger.warn({
            service: "notification-service",
            operation: "sse_client_not_connected",
            user_id: data.user_id
          });
        }

        // ---------------------------------------
        // 10. Kafka offset commit happens automatically
        // ---------------------------------------
        logger.info({
          service: "notification-service",
          operation: "message_processed_and_offset_committed",
          order_id: data.order_id,
          offset: message.offset
        });

      } catch (error) {

        logger.error({
          service: "notification-service",
          operation: "notification_processing_failed",
          error: error.message,
          topic: "orders.created"
        });

        // ---------------------------------------
        // 11. Kafka retry strategy
        // ---------------------------------------
        // NOTE:
        // Kafka does NOT requeue like RabbitMQ.
        // This will cause retry via reprocessing OR DLQ pattern.

        throw error; // triggers retry depending on config
      }
    },
  });
}

module.exports = startKafkaConsumer;