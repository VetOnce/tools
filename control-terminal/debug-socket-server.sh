#!/bin/bash

# Socket Server Debug Script
# Specifically designed to debug socket-server build failures

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print section headers
print_header() {
    echo ""
    echo -e "${MAGENTA}========================================${NC}"
    echo -e "${MAGENTA}$1${NC}"
    echo -e "${MAGENTA}========================================${NC}"
}

# Check local socket-server setup
check_local_setup() {
    print_header "Checking Local Socket Server Setup"
    
    local socket_dir="/Users/chrisshaw/Code/project-mgmt-poc/socket-server"
    
    if [ ! -d "$socket_dir" ]; then
        print_message $RED "Socket server directory not found!"
        return 1
    fi
    
    cd "$socket_dir"
    
    # Check package.json
    if [ -f "package.json" ]; then
        print_message $GREEN "✓ package.json found"
        print_message $CYAN "Dependencies:"
        cat package.json | grep -E '"(dependencies|devDependencies)"' -A 10 | grep -E '".+":' | sed 's/[",]//g'
    else
        print_message $RED "✗ package.json not found!"
    fi
    
    # Check for main server file
    for file in index.js server.js app.js index.ts server.ts app.ts; do
        if [ -f "$file" ]; then
            print_message $GREEN "✓ Server file found: $file"
            break
        fi
    done
    
    # Check node_modules
    if [ -d "node_modules" ]; then
        print_message $GREEN "✓ node_modules exists"
    else
        print_message $YELLOW "⚠ node_modules not found - need to run npm install"
    fi
    
    # Check for TypeScript config if using TS
    if ls *.ts &> /dev/null; then
        if [ -f "tsconfig.json" ]; then
            print_message $GREEN "✓ tsconfig.json found"
        else
            print_message $YELLOW "⚠ TypeScript files found but no tsconfig.json"
        fi
    fi
}

# Check Railway deployment logs
check_railway_logs() {
    print_header "Checking Railway Deployment Logs"
    
    if ! command -v railway &> /dev/null; then
        print_message $RED "Railway CLI not installed"
        return 1
    fi
    
    # Get recent deployments
    print_message $BLUE "Recent deployments:"
    railway status || print_message $YELLOW "Could not fetch deployment status"
    
    # Show build logs
    print_message $BLUE "\nFetching build logs for socket-server..."
    railway logs --service=socket-server | head -100 | grep -E "(error|Error|ERROR|failed|Failed|FAILED|npm ERR|Build failed)" -B 2 -A 2 || print_message $YELLOW "No errors found in recent logs"
}

# Analyze common socket server issues
analyze_common_issues() {
    print_header "Analyzing Common Socket Server Issues"
    
    local issues_found=0
    
    # Check for missing dependencies
    print_message $BLUE "Checking for missing dependencies..."
    cd /Users/chrisshaw/Code/project-mgmt-poc/socket-server
    
    if [ -f "package.json" ]; then
        # Check if socket.io is installed
        if ! grep -q '"socket.io"' package.json; then
            print_message $YELLOW "⚠ socket.io not found in dependencies"
            ((issues_found++))
        fi
        
        # Check for build script
        if ! grep -q '"build"' package.json; then
            print_message $YELLOW "⚠ No build script in package.json"
            ((issues_found++))
        fi
        
        # Check for start script
        if ! grep -q '"start"' package.json; then
            print_message $YELLOW "⚠ No start script in package.json"
            ((issues_found++))
        fi
    fi
    
    # Check Railway configuration
    if [ -f "../railway.json" ] || [ -f "../railway.toml" ]; then
        print_message $GREEN "✓ Railway configuration found"
        
        # Check for socket-server service definition
        if [ -f "../railway.toml" ]; then
            if grep -q "socket-server" ../railway.toml; then
                print_message $GREEN "✓ socket-server service defined in railway.toml"
            else
                print_message $YELLOW "⚠ socket-server service not found in railway.toml"
                ((issues_found++))
            fi
        fi
    else
        print_message $YELLOW "⚠ No Railway configuration files found"
        ((issues_found++))
    fi
    
    if [ $issues_found -eq 0 ]; then
        print_message $GREEN "No common issues detected"
    else
        print_message $YELLOW "Found $issues_found potential issues"
    fi
}

# Suggest fixes
suggest_fixes() {
    print_header "Suggested Fixes"
    
    print_message $CYAN "1. Ensure socket-server has all dependencies:"
    echo "   cd socket-server && npm install"
    
    print_message $CYAN "\n2. Add required scripts to socket-server/package.json:"
    echo '   "scripts": {'
    echo '     "start": "node index.js",'
    echo '     "build": "echo \"No build step required\""'
    echo '   }'
    
    print_message $CYAN "\n3. Verify Railway service configuration in railway.toml:"
    echo '   [[services]]'
    echo '   name = "socket-server"'
    echo '   source = "socket-server"'
    echo '   startCommand = "npm start"'
    echo '   buildCommand = "npm install"'
    
    print_message $CYAN "\n4. Check environment variables:"
    echo "   railway variables --service=socket-server"
    
    print_message $CYAN "\n5. Manual deployment command:"
    echo "   cd socket-server && railway up --service=socket-server"
}

# Interactive menu
show_menu() {
    while true; do
        print_header "Socket Server Debug Menu"
        echo "1. Check local setup"
        echo "2. View Railway logs (live)"
        echo "3. View build errors only"
        echo "4. Analyze common issues"
        echo "5. Show suggested fixes"
        echo "6. Run all checks"
        echo "7. Open Railway dashboard"
        echo "0. Exit"
        
        read -p "Select option: " choice
        
        case $choice in
            1) check_local_setup ;;
            2) railway logs --service=socket-server --follow ;;
            3) check_railway_logs ;;
            4) analyze_common_issues ;;
            5) suggest_fixes ;;
            6) 
                check_local_setup
                check_railway_logs
                analyze_common_issues
                suggest_fixes
                ;;
            7) railway open ;;
            0) exit 0 ;;
            *) print_message $RED "Invalid option" ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Main execution
main() {
    print_message $BLUE "Socket Server Debug Tool"
    print_message $BLUE "======================="
    
    # Change to project directory
    cd /Users/chrisshaw/Code/project-mgmt-poc
    
    # Quick check if we're in the right directory
    if [ ! -d "socket-server" ]; then
        print_message $RED "Error: socket-server directory not found!"
        print_message $YELLOW "Please run this script from the project root directory"
        exit 1
    fi
    
    # If arguments provided, run specific checks
    if [ "$1" == "--all" ]; then
        check_local_setup
        check_railway_logs
        analyze_common_issues
        suggest_fixes
    elif [ "$1" == "--logs" ]; then
        railway logs --service=socket-server --follow
    elif [ "$1" == "--errors" ]; then
        check_railway_logs
    else
        show_menu
    fi
}

# Run main function
main "$@"