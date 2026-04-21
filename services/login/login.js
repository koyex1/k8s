const amqp = require('amqplib');

async function send() {
  const conn = await amqp.connect('amqp://rabbitmq');
  const ch = await conn.createChannel();

  await ch.assertQueue('login');

  ch.sendToQueue('login', Buffer.from('User logged in'));
}

send();