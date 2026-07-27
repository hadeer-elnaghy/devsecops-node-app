FROM node:18-alpine

RUN apk update && apk upgrade

WORKDIR /app

# Copy dependency manifests
COPY package*.json ./

# Install production dependencies and clean cache
RUN npm ci --omit=dev && npm cache clean --force

# Copy application source code
COPY . .

EXPOSE 3000

CMD ["node", "server.js"]