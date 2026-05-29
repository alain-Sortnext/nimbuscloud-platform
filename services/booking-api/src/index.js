/**
 * NimbusCloud Booking API
 * v2.4.1
 * Manages client booking and scheduling events
 */
const express = require('express');
const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand, GetCommand, QueryCommand } = require('@aws-sdk/lib-dynamodb');
const client = require('prom-client');
const winston = require('winston');
const { v4: uuidv4 } = require('uuid');

const app = express();
app.use(express.json());

// ─── Logger ───────────────────────────────────────────────────────────────────
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [new winston.transports.Console()]
});

// ─── Prometheus metrics ───────────────────────────────────────────────────────
const register = new client.Registry();
client.collectDefaultMetrics({ register });

const httpRequestDuration = new client.Histogram({
  name: 'booking_api_http_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status'],
  buckets: [0.1, 0.5, 1, 2, 5],
  registers: [register]
});

const bookingCreatedCounter = new client.Counter({
  name: 'booking_api_bookings_created_total',
  help: 'Total bookings created',
  registers: [register]
});

// ─── DynamoDB ────────────────────────────────────────────────────────────────
const dbClient = new DynamoDBClient({
  region: process.env.AWS_REGION || 'eu-west-2'
});
const docClient = DynamoDBDocumentClient.from(dbClient);
const TABLE_NAME = process.env.DYNAMODB_TABLE || 'nimbuscloud-sessions';

// ─── Routes ───────────────────────────────────────────────────────────────────
app.get('/healthz', (req, res) => {
  res.json({ status: 'ok', service: 'booking-api', version: '2.4.1', timestamp: new Date().toISOString() });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.post('/api/v1/bookings', async (req, res) => {
  const end = httpRequestDuration.startTimer({ method: 'POST', route: '/api/v1/bookings' });
  try {
    const { clientId, slotDate, slotTime, serviceType } = req.body;
    if (!clientId || !slotDate || !slotTime) {
      end({ status: '400' });
      return res.status(400).json({ error: 'clientId, slotDate, slotTime required' });
    }
    const bookingId = uuidv4();
    await docClient.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        session_id: `booking#${bookingId}`,
        user_id: clientId,
        booking_id: bookingId,
        slot_date: slotDate,
        slot_time: slotTime,
        service_type: serviceType || 'standard',
        status: 'confirmed',
        created_at: new Date().toISOString(),
        expires_at: Math.floor(Date.now() / 1000) + 86400 * 30
      }
    }));
    bookingCreatedCounter.inc();
    end({ status: '201' });
    logger.info({ msg: 'booking created', bookingId, clientId });
    res.status(201).json({ bookingId, status: 'confirmed' });
  } catch (err) {
    end({ status: '500' });
    logger.error({ msg: 'booking creation failed', error: err.message });
    res.status(500).json({ error: 'internal server error' });
  }
});

app.get('/api/v1/bookings/:bookingId', async (req, res) => {
  const end = httpRequestDuration.startTimer({ method: 'GET', route: '/api/v1/bookings/:id' });
  try {
    const result = await docClient.send(new GetCommand({
      TableName: TABLE_NAME,
      Key: { session_id: `booking#${req.params.bookingId}`, user_id: req.query.clientId }
    }));
    if (!result.Item) {
      end({ status: '404' });
      return res.status(404).json({ error: 'booking not found' });
    }
    end({ status: '200' });
    res.json(result.Item);
  } catch (err) {
    end({ status: '500' });
    logger.error({ msg: 'booking fetch failed', error: err.message });
    res.status(500).json({ error: 'internal server error' });
  }
});

// ─── Start ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  logger.info({ msg: `booking-api started`, port: PORT, env: process.env.ENVIRONMENT });
});

module.exports = app;
