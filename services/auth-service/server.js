const http = require('http');
const AWS = require('aws-sdk');

const port = process.env.PORT || 3003;

// Initialize AWS Secrets Manager client
const secretsManager = new AWS.SecretsManager({
    region: process.env.AWS_REGION || 'eu-west-2'
});

// Function to get secret from Secrets Manager
async function getSecret() {
    try {
        const data = await secretsManager.getSecretValue({
            SecretId: 'nimbuscloud/db-password'
        }).promise();
        
        if (data.SecretString) {
            const secret = JSON.parse(data.SecretString);
            console.log('✅ Successfully retrieved DB password from Secrets Manager');
            return secret.DB_PASSWORD;
        }
    } catch (error) {
        console.error('❌ Failed to retrieve secret from Secrets Manager:', error.message);
        return null;
    }
}

// Get secret and start server
async function startServer() {
    const dbPassword = await getSecret();
    
    if (dbPassword) {
        console.log(`DB Password retrieved (length: ${dbPassword.length})`);
        process.env.DB_PASSWORD = dbPassword;
    } else {
        console.log('⚠️ Using fallback or environment variable for DB_PASSWORD');
    }

    const server = http.createServer((req, res) => {
        if (req.url === '/health' || req.url === '/healthz') {
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify({ 
                status: 'healthy', 
                service: 'auth-service',
                'secrets-manager': dbPassword ? 'enabled' : 'disabled'
            }));
        } else {
            res.writeHead(200, { 'Content-Type': 'text/plain' });
            res.end('Auth Service (Node.js - Secrets Manager)');
        }
    });

    server.listen(port, () => {
        console.log(`auth-service starting on port ${port}`);
    });
}

startServer().catch(console.error);
