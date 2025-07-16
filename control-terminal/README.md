# Control Terminal - Railway Debugging Tools

This folder contains tools for debugging Railway deployments, particularly for the socket-server build issues.

## Scripts

### 1. `open-railway-terminal.sh`
Opens Railway log monitoring in a new terminal window.

```bash
./open-railway-terminal.sh
```

### 2. `railway-logs.sh`
Main Railway log monitoring script with interactive options.

```bash
# Monitor all services
./railway-logs.sh

# Monitor specific service
./railway-logs.sh socket-server
```

### 3. `debug-socket-server.sh`
Comprehensive debugging tool for socket-server issues.

```bash
# Interactive menu
./debug-socket-server.sh

# Run all checks
./debug-socket-server.sh --all

# View live logs
./debug-socket-server.sh --logs

# View only errors
./debug-socket-server.sh --errors
```

## Features

- **Automatic Railway CLI Installation**: Checks and installs Railway CLI if needed
- **Login Management**: Handles Railway authentication
- **Project Linking**: Links to Railway projects from current directory
- **Log Monitoring**: Real-time log streaming with filtering
- **Error Detection**: Finds and highlights build errors
- **Issue Analysis**: Checks for common configuration problems
- **Fix Suggestions**: Provides actionable solutions

## Usage for Socket-Server Debugging

1. Navigate to the project directory:
   ```bash
   cd /Users/chrisshaw/Code/project-mgmt-poc
   ```

2. Run the debug script:
   ```bash
   /Users/chrisshaw/Code/tools/control-terminal/debug-socket-server.sh --all
   ```

3. The script will:
   - Check local socket-server setup
   - Fetch Railway deployment logs
   - Identify common issues
   - Suggest fixes

## Common Socket-Server Issues

1. **Missing Dependencies**: Ensure `socket.io` is in package.json
2. **No Build Script**: Add a build script even if it's just `echo "No build"`
3. **No Start Script**: Define how to start the server
4. **Railway Config**: Ensure socket-server service is defined in railway.toml
5. **Environment Variables**: Check all required env vars are set

## Quick Fixes

```bash
# Install dependencies
cd socket-server && npm install

# Add to package.json
"scripts": {
  "start": "node index.js",
  "build": "echo 'No build required'"
}

# Deploy manually
railway up --service=socket-server
```