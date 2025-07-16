#!/bin/bash

# Railway Log Monitor Script
# This script opens a new terminal window and monitors Railway logs

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if Railway CLI is installed
check_railway_cli() {
    if ! command -v railway &> /dev/null; then
        print_message $RED "Railway CLI is not installed!"
        print_message $YELLOW "Installing Railway CLI..."
        
        # Install Railway CLI based on the platform
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            brew install railway || curl -fsSL https://railway.app/install.sh | sh
        else
            # Linux/Unix
            curl -fsSL https://railway.app/install.sh | sh
        fi
        
        if ! command -v railway &> /dev/null; then
            print_message $RED "Failed to install Railway CLI"
            exit 1
        fi
    fi
    print_message $GREEN "Railway CLI is installed"
}

# Function to check Railway login status
check_railway_login() {
    if ! railway whoami &> /dev/null; then
        print_message $YELLOW "Not logged in to Railway"
        print_message $BLUE "Opening Railway login..."
        railway login
    else
        local user=$(railway whoami 2>/dev/null)
        print_message $GREEN "Logged in as: $user"
    fi
}

# Function to list Railway projects
list_projects() {
    print_message $BLUE "\nFetching Railway projects..."
    railway list
}

# Function to monitor logs
monitor_logs() {
    local service=$1
    
    if [ -z "$service" ]; then
        print_message $YELLOW "\nAvailable options:"
        echo "1. Monitor socket-server logs"
        echo "2. Monitor main app logs"
        echo "3. Monitor all services"
        echo "4. Custom service name"
        
        read -p "Select option (1-4): " option
        
        case $option in
            1)
                service="socket-server"
                ;;
            2)
                service="web"
                ;;
            3)
                service=""
                ;;
            4)
                read -p "Enter service name: " service
                ;;
            *)
                print_message $RED "Invalid option"
                exit 1
                ;;
        esac
    fi
    
    print_message $GREEN "\nStarting log monitoring..."
    
    if [ -z "$service" ]; then
        print_message $BLUE "Monitoring all services..."
        railway logs --follow
    else
        print_message $BLUE "Monitoring $service logs..."
        railway logs --service=$service --follow
    fi
}

# Function to show deployment status
show_deployment_status() {
    print_message $BLUE "\nChecking deployment status..."
    railway status
}

# Main execution
main() {
    print_message $BLUE "Railway Control Terminal"
    print_message $BLUE "======================="
    
    # Check and setup Railway CLI
    check_railway_cli
    check_railway_login
    
    # Show current project context
    if [ -f "railway.json" ] || [ -f "railway.toml" ]; then
        print_message $GREEN "Railway configuration found in current directory"
    else
        print_message $YELLOW "No Railway configuration found in current directory"
        list_projects
        
        read -p "Do you want to link a project? (y/n): " link_project
        if [[ $link_project == "y" ]]; then
            railway link
        fi
    fi
    
    # Show deployment status
    show_deployment_status
    
    # Start monitoring logs
    monitor_logs "$1"
}

# Handle script arguments
case "$1" in
    --help|-h)
        echo "Usage: $0 [service-name]"
        echo "  service-name: Optional. Name of the service to monitor (e.g., socket-server, web)"
        echo ""
        echo "If no service name is provided, you'll be prompted to select one."
        exit 0
        ;;
    *)
        main "$1"
        ;;
esac