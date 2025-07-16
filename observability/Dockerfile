FROM oven/bun:1-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY bun.lockb ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy source files
COPY . .

# Expose port
EXPOSE 4000

# Start the server
CMD ["bun", "src/index.ts"]