FROM node:18-alpine

RUN apk update && apk upgrade

WORKDIR /app

# Copy dependency manifests
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy application source code
COPY . .

EXPOSE 3000

CMD ["node", "server.js"]