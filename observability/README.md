# Observability Server

Real-time monitoring server for Claude Code hooks integration with Manager dashboard.

## Features

- 🔄 Real-time WebSocket streaming
- 📊 Event collection and storage
- 🔒 API key authentication (optional)
- 📈 Session tracking and analytics
- 🚀 High-performance with Bun runtime

## Requirements

- Bun 1.0+ or Node.js 18+
- SQLite3

## Installation

```bash
# Using Bun (recommended)
bun install

# Using npm
npm install
```

## Running Locally

```bash
# Development mode
bun run dev

# Production mode
bun start
```

The server will start on http://localhost:4000

## API Endpoints

- `GET /` - Health check
- `GET /health` - Server status
- `POST /events` - Submit events
- `WS /stream` - WebSocket connection for real-time updates

## Environment Variables

```env
# Server Configuration
PORT=4000
NODE_ENV=production

# Security
ALLOWED_ORIGINS=https://admin.shawandpartners.com,http://localhost:3000
API_KEY_REQUIRED=false
VALID_API_KEYS=key1,key2

# Database
DB_PATH=./data/observability.db

# Performance
MAX_EVENTS_PER_SESSION=10000
EVENT_RETENTION_DAYS=30
```

## Railway Deployment

1. Add as a new service in Railway
2. Set root directory to this folder
3. Use the included Dockerfile
4. Generate a public domain
5. Set environment variables

## Docker

```bash
# Build
docker build -t observability-server .

# Run
docker run -p 4000:4000 observability-server
```

## Integration with Manager

In your Manager app, set:
```env
NEXT_PUBLIC_OBSERVABILITY_SERVER_URL=https://your-domain.railway.app
NEXT_PUBLIC_OBSERVABILITY_WEBSOCKET_URL=wss://your-domain.railway.app
```

## Claude Code Hooks

The server receives events from Claude Code hooks installed in project directories. Events include:
- Tool usage (bash, read, write, etc.)
- Errors and exceptions
- Performance metrics
- Session information

## Database Schema

Events are stored in SQLite with:
- Session tracking
- Event timestamps
- Tool usage statistics
- Error logs
- Performance metrics
