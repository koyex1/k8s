const amqp = require("amqplib");

const pool = require("./db");
const logger = require("./logger");

async function startRabbitmqConsumer() {

  const connection = await amqp.connect(
    `amqp://${process.env.RABBITMQ_DEFAULT_USER}:${process.env.RABBITMQ_DEFAULT_PASS}@${process.env.RABBITMQ_HOST}:${process.env.RABBITMQ_PORT}`
  );

  const channel = await connection.createChannel();


  logger.info({
    service: "notification-service",
    operation: "rabbitmq_connected",
    queue: "notification.orders.created.queue"
  });

  channel.consume(
    "notification.orders.created.queue",
    async (msg) => {

      if (!msg) {
        return;
      }

      try {

        const data = JSON.parse(
          msg.content.toString()
        );

        logger.info({
          service: "notification-service",
          operation: "message_received",
          user_id: data.user_id,
          username: data.username,
          order_id: data.order_id
        });

        logger.info({
          service: "notification-service",
          operation: "processing_delay_started",
          delay_seconds: 10
        });

        /*
          simulate processing delay
        */
        await new Promise(
          (resolve) =>
            setTimeout(resolve, 10000)
        );

        const notificationMessage =
          `Hello ${data.username}, your order has been processed successfully via RabbitMQ`;

        /*
          save notification
        */
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

        /*
          send realtime notification via SSE
        */
        const client =
          global.sseClients.get(
            String(data.user_id)
          );

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

        /*
          acknowledge message
        */
        channel.ack(msg);

        logger.info({
          service: "notification-service",
          operation: "message_acknowledged",
          order_id: data.order_id
        });

      } catch (error) {

        logger.error({
          service: "notification-service",
          operation: "notification_processing_failed",
          error: error.message
        });

        channel.nack(
          msg,
          false,
          true
        );
      }
    }
  );
}

module.exports = startRabbitmqConsumer;