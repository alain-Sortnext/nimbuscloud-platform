"""
NimbusCloud Payment API
v2.4.1
Processes payment webhooks and authorisation via Stripe
"""
import os
import logging
import json
from datetime import datetime
from flask import Flask, request, jsonify
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import boto3
import stripe

app = Flask(__name__)

# ─── Logging ──────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=os.getenv('LOG_LEVEL', 'INFO'),
    format='%(asctime)s %(levelname)s %(name)s %(message)s'
)
logger = logging.getLogger('payment-api')

# ─── Prometheus metrics ───────────────────────────────────────────────────────
payment_requests = Counter('payment_api_requests_total', 'Total payment requests', ['method', 'endpoint', 'status'])
payment_duration = Histogram('payment_api_duration_seconds', 'Payment request duration', ['endpoint'])
webhook_counter = Counter('payment_api_webhooks_total', 'Total webhooks received', ['event_type'])

# ─── Stripe ───────────────────────────────────────────────────────────────────
stripe.api_key = os.getenv('STRIPE_API_KEY', '')

# ─── SQS ─────────────────────────────────────────────────────────────────────
sqs = boto3.client('sqs', region_name=os.getenv('AWS_REGION', 'eu-west-2'))
QUEUE_URL = os.getenv('SQS_QUEUE_URL', '')

@app.route('/healthz')
def health():
    return jsonify({'status': 'ok', 'service': 'payment-api', 'version': '2.4.1', 'timestamp': datetime.utcnow().isoformat()})

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/api/v1/payments/webhook', methods=['POST'])
def stripe_webhook():
    payload = request.get_data()
    sig_header = request.headers.get('Stripe-Signature')
    webhook_secret = os.getenv('STRIPE_WEBHOOK_SECRET', '')

    try:
        event = stripe.Webhook.construct_event(payload, sig_header, webhook_secret)
    except ValueError:
        logger.error('Invalid Stripe payload')
        payment_requests.labels('POST', '/webhook', '400').inc()
        return jsonify({'error': 'Invalid payload'}), 400
    except stripe.error.SignatureVerificationError:
        logger.error('Stripe signature verification failed')
        payment_requests.labels('POST', '/webhook', '401').inc()
        return jsonify({'error': 'Invalid signature'}), 401

    webhook_counter.labels(event['type']).inc()
    logger.info(f"Received Stripe event: {event['type']}")

    if event['type'] == 'payment_intent.succeeded':
        pi = event['data']['object']
        if QUEUE_URL:
            sqs.send_message(
                QueueUrl=QUEUE_URL,
                MessageBody=json.dumps({
                    'type': 'payment_confirmed',
                    'payment_intent_id': pi['id'],
                    'amount': pi['amount'],
                    'currency': pi['currency'],
                    'timestamp': datetime.utcnow().isoformat()
                })
            )

    payment_requests.labels('POST', '/webhook', '200').inc()
    return jsonify({'received': True})

@app.route('/api/v1/payments/authorise', methods=['POST'])
def authorise_payment():
    data = request.json
    if not data or 'amount' not in data or 'currency' not in data:
        payment_requests.labels('POST', '/authorise', '400').inc()
        return jsonify({'error': 'amount and currency required'}), 400

    try:
        intent = stripe.PaymentIntent.create(
            amount=data['amount'],
            currency=data.get('currency', 'gbp'),
            metadata={'client_id': data.get('client_id', 'unknown')}
        )
        payment_requests.labels('POST', '/authorise', '200').inc()
        return jsonify({'client_secret': intent.client_secret, 'payment_intent_id': intent.id})
    except stripe.error.StripeError as e:
        logger.error(f'Stripe error: {e}')
        payment_requests.labels('POST', '/authorise', '500').inc()
        return jsonify({'error': 'payment processing failed'}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 3002))
    logger.info(f'payment-api starting on port {port}')
    app.run(host='0.0.0.0', port=port)
