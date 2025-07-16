# Shaw & Partners Tools

A collection of development tools and services for Shaw & Partners projects.

## Tools

### Observability Server
Real-time monitoring and observability server for Claude Code hooks integration.

- **Location**: `/observability`
- **Purpose**: Collects and streams real-time events from Claude Code to connected dashboards
- **Tech**: Bun, TypeScript, WebSockets, SQLite

## Structure

```
tools/
├── observability/          # Real-time observability server
│   ├── src/               # Source code
│   ├── Dockerfile         # Docker configuration
│   └── package.json       # Dependencies
└── README.md              # This file
```

## Deployment

Each tool can be deployed independently to Railway or other platforms.

### Observability Server

See [observability/README.md](./observability/README.md) for deployment instructions.

## Contributing

Each tool should be self-contained with its own:
- README.md
- Dockerfile (if applicable)
- Dependencies
- Tests

## License

Private repository for Shaw & Partners internal use.