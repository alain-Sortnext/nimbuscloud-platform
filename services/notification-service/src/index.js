/**
 * NimbusCloud Notification Service
 * v2.4.1
 * Dispatches email and SMS notifications via SQS + SES
 */
const express = require('express');
const { SQSClient, ReceiveMessageCommand, DeleteMessageCommand } = require('@aws-sdk/client-sqs');
const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');
const client = require('prom-client');
const winston = require('winston');

const app = express();
app.use(express.json());

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(winston.format.timestamp(), winston.format.json()),
  transports: [new winston.transports.Console()]
});

const register = new client.Registry();
client.collectDefaultMetrics({ register });

const notificationsSent = new client.Counter({
  name: 'notification_service_sent_total',
  help: 'Total notifications sent',
  labelNames: ['type', 'status'],
  registers: [register]
});

const queueDepth = new client.Gauge({
  name: 'notification_service_queue_depth',
  help: 'Approximate SQS queue depth',
  registers: [register]
});

const sqsClient = new SQSClient({ region: process.env.AWS_REGION || 'eu-west-2' });
const sesClient = new SESClient({ region: process.env.AWS_REGION || 'eu-west-2' });
const QUEUE_URL = process.env.SQS_QUEUE_URL || '';
const FROM_ADDRESS = process.env.SES_FROM_ADDRESS || 'noreply@nimbuscloud.io';

app.get('/healthz', (req, res) => {
  res.json({ status: 'ok', service: 'notification-service', version: '2.4.1' });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Poll SQS for notification events
async function pollQueue() {
  if (!QUEUE_URL) {
    logger.warn('SQS_QUEUE_URL not set — notification polling disabled');
    return;
  }
  try {
    const response = await sqsClient.send(new ReceiveMessageCommand({
      QueueUrl: QUEUE_URL,
      MaxNumberOfMessages: 10,
      WaitTimeSeconds: 20
    }));

    if (response.Messages) {
      queueDepth.set(response.Messages.length);
      for (const message of response.Messages) {
        const body = JSON.parse(message.Body);
        await processNotification(body);
        await sqsClient.send(new DeleteMessageCommand({
          QueueUrl: QUEUE_URL,
          ReceiptHandle: message.ReceiptHandle
        }));
      }
    }
  } catch (err) {
    logger.error({ msg: 'SQS poll error', error: err.message });
  }
  setTimeout(pollQueue, 1000);
}

async function processNotification(event) {
  try {
    if (event.type === 'payment_confirmed') {
      await sesClient.send(new SendEmailCommand({
        Source: FROM_ADDRESS,
        Destination: { ToAddresses: [event.customer_email || 'noreply@nimbuscloud.io'] },
        Message: {
          Subject: { Data: 'Payment Confirmed — NimbusCloud' },
          Body: { Text: { Data: `Your payment of £${(event.amount / 100).toFixed(2)} has been confirmed.` } }
        }
      }));
      notificationsSent.labels('email', 'success').inc();
    }
  } catch (err) {
    logger.error({ msg: 'notification send failed', error: err.message });
    notificationsSent.labels('email', 'failure').inc();
  }
}

const PORT = process.env.PORT || 3004;
app.listen(PORT, () => {
  logger.info({ msg: 'notification-service started', port: PORT });
  if (QUEUE_URL) pollQueue();
});

module.exports = app;
