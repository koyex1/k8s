require("dotenv").config();

const express = require("express");

const logger = require("./logger");
const startRabbitmqConsumer = require("./rabbitmq_consumer");
const startKafkaConsumer = require("./kafka_consumer");


const app = express();

app.use(express.json());

/*
  userId -> SSE connection
*/
const clients = new Map();

/*
  Export clients map globally
*/
global.sseClients = clients;

/*
  SSE endpoint
*/
app.get(
  "/notifications/stream",
  (req, res) => {

    const userId = req.headers["x-user-id"];
    const username = req.headers["x-username"];

    if (!userId || !username) {

      logger.error({
        service: "notification-service",
        operation: "sse_auth_failed"
      });

      return res.status(401).json({
        error: "Unauthorized"
      });
    }

    logger.info({
      service: "notification-service",
      operation: "sse_connected",
      user_id: userId,
      username
    });

    /*
      SSE headers
    */
    res.setHeader(
      "Content-Type",
      "text/event-stream"
    );

    res.setHeader(
      "Cache-Control",
      "no-cache"
    );

    res.setHeader(
      "Connection",
      "keep-alive"
    );

    res.flushHeaders();

    /*
      Save connection
    */
    clients.set(userId, res);

    /*
      Initial connection message
    */
    res.write(
      `data: ${JSON.stringify({
        type: "connected",
        message: "SSE connection established"
      })}\n\n`
    );

    /*
      Remove disconnected clients
    */
    req.on(
      "close",
      () => {

        logger.info({
          service: "notification-service",
          operation: "sse_disconnected",
          user_id: userId
        });

        clients.delete(userId);

        res.end();
      }
    );
  }
);

app.listen(
  3000,
  async () => {

    logger.info({
      service: "notification-service",
      operation: "service_started",
      port: 3000
    });

    await startRabbitmqConsumer();
    await startKafkaConsumer();
  }
);