FROM node:18-alpine

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy application source
COPY server.js ./

# Expose port
EXPOSE 3000

# Start application
CMD ["npm", "start"]
