FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json first for caching
COPY package*.json ./

# Install only production dependencies
RUN npm install --production

# Copy the rest of the application source code
COPY . ./

# Set NODE_ENV to production
ENV NODE_ENV=production

# Expose the application port
EXPOSE 3000

# Use a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Command to run the app
CMD ["node", "app.js"]
