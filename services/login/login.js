const express = require("express");
const bcrypt = require("bcrypt");
const axios = require("axios");
const { Pool } = require("pg");
const winston = require("winston");
const Redis = require("ioredis");
const jwt = require("jsonwebtoken");


const app = express();
app.use(express.json());

// CONFIG
const APISIX_ADMIN_URL = process.env.APISIX_ADMIN_URL || "http://apisix:9180";
const APISIX_ADMIN_KEY = process.env.APISIX_ADMIN_KEY || "edd1c9f034335f136f87ad84b625c8f1";
const APISIX_CONSUMER_NAME = process.env.APISIX_CONSUMER_NAME || "dev_app";
const APISIX_CONSUMER_KEY = process.env.APISIX_CONSUMER_KEY || "dev_app_key";

const REDIS_URL = process.env.REDIS_URL || "redis://redis:6379";

// Infra
const db = new Pool({
  host: process.env.DB_HOST || "postgres",
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || "appdb",
  user: process.env.DB_USER || "user",
  password: process.env.DB_PASSWORD || "pass",

  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000
});

const redis = new Redis(REDIS_URL);

// Logging
const logger = winston.createLogger({
  level: "info",
  format: winston.format.json(),
  transports: [new winston.transports.Console()]
});

// LOGIN
app.post("/login", async (req, res) => {
  const { username, password } = req.body;

  logger.info("login_attempt", { username });

  if (!username || !password) {
    return res.status(400).json({ error: "Missing credentials" });
  }

  try {
    // 1. RATE LIMIT (Redis)
    const attemptsKey = `login_attempts:${username}`;
    const attempts = await redis.incr(attemptsKey); //incr means count++ attempts 

    if (attempts === 1) {
      await redis.expire(attemptsKey, 60); // 1 min window 
    }

    if (attempts > 5) {
      logger.warn("too_many_attempts", { username });
      return res.status(429).json({ error: "Too many attempts. Try later." });
    }

    // 2. CHECK CACHE (OPTIONAL)
    const cachedUser = await redis.get(`user:${username}`);
    let user;

    if (cachedUser) {
      user = JSON.parse(cachedUser);
      logger.info("cache_hit", { username });
    } else {
      const result = await db.query(
        "SELECT id, username, email, password_hash FROM users WHERE username=$1",
        [username]
      );

      if (result.rows.length === 0) {
        return res.status(401).json({ error: "Invalid credentials" });
      }

      user = result.rows[0];

      // Cache user for 5 mins
      await redis.set(`user:${username}`, JSON.stringify(user), "EX", 300);
    }

    // 3. PASSWORD CHECK
    const valid = await bcrypt.compare(password, user.password_hash);

    if (!valid) {
      return res.status(401).json({ error: "Invalid credentials" });
    }

    // 4. Generate JWT - apisix will decrypt and send the decrypted values via headers 
    //to other routes that need them.

    const token = jwt.sign(
      {
        email: user.email,
        user_id: user.id,
        username: user.username,
        azp: APISIX_CONSUMER_NAME,
        key: APISIX_CONSUMER_KEY
      },
      process.env.JWT_SECRET || "my-secret-key",
      { expiresIn: "1h" }
    );

    // 5. STORE SESSION (AUDIT ONLY so reason why get is not called on it ever.)
    await redis.set(
      `session:${user.id}`,
      JSON.stringify({
        username: user.username,
        login_time: new Date().toISOString()
      }),
      "EX",
      3600
    );

    // Reset failed attempts on login success
    await redis.del(attemptsKey);

    logger.info("login_success", { username, user_id: user.id });

    res.json({
      access_token: token,
      token_type: "Bearer",
      expires_in: 3600,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
      }
    });

  } catch (err) {
    logger.error("login_error", {
      message: err.message,
      apisix_error: err.response?.data
    });

    res.status(500).json({ error: "Internal error" });
  }
});

// VERIFY (DEBUG ONLY)
app.get("/verify", (req, res) => {
  res.json({
    message: "Verification handled by APISIX"
  });
});

// HEALTH
app.get("/health", (req, res) => {
  res.json({ status: "healthy", service: "login-svc" });
});

app.listen(3000, () => {
  logger.info("login_service_started", { port: 3000 });
});