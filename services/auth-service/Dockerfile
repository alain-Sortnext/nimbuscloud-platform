FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY server.js ./

EXPOSE 3003

CMD ["npm", "start"]
