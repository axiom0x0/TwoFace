#!/bin/bash

# TwoFace Installer v1.0.0
# This script sets up TwoFace, a file synchronization tool for dual-directory workflows
# with macOS notifications on any macOS system.

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration - Edit these paths as needed
DEFAULT_BASE_DIR="$HOME/code"
DEFAULT_WRITE_DIR="write"
DEFAULT_DEPLOY_DIR="deploy"

echo -e "${BLUE}🎭 TwoFace Installer v1.0.0${NC}"
echo "TwoFace: A file synchronization tool for dual-directory workflows."
echo

# Get installation directory
read -p "Base directory (default: $DEFAULT_BASE_DIR): " BASE_DIR
BASE_DIR=${BASE_DIR:-$DEFAULT_BASE_DIR}

read -p "Write subdirectory name (default: $DEFAULT_WRITE_DIR): " WRITE_NAME
WRITE_NAME=${WRITE_NAME:-$DEFAULT_WRITE_DIR}

read -p "Deploy subdirectory name (default: $DEFAULT_DEPLOY_DIR): " DEPLOY_NAME
DEPLOY_NAME=${DEPLOY_NAME:-$DEFAULT_DEPLOY_DIR}

WRITE_DIR="$BASE_DIR/$WRITE_NAME"
DEPLOY_DIR="$BASE_DIR/$DEPLOY_NAME"
SCRIPT_DIR="$BASE_DIR"

echo
echo -e "${BLUE}📋 Installation Summary:${NC}"
echo "  Base directory: $BASE_DIR"
echo "  Write directory: $WRITE_DIR"
echo "  Deploy directory: $DEPLOY_DIR"
echo
read -p "Continue with installation? (y/N): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo
echo -e "${BLUE}📦 Checking dependencies...${NC}"

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}❌ Homebrew is not installed.${NC}"
    echo -e "${YELLOW}Please install Homebrew first: https://brew.sh${NC}"
    exit 1
fi

# Install fswatch if not already installed
echo -e "${BLUE}📦 Checking fswatch installation...${NC}"
if ! command -v fswatch &> /dev/null; then
    echo -e "${YELLOW}Installing fswatch...${NC}"
    brew install fswatch
    echo -e "${GREEN}✅ fswatch installed successfully${NC}"
else
    echo -e "${GREEN}✅ fswatch is already installed${NC}"
fi

# Create directories
echo -e "${BLUE}📁 Creating directories...${NC}"
mkdir -p "$BASE_DIR"
mkdir -p "$WRITE_DIR"
mkdir -p "$DEPLOY_DIR"
echo -e "${GREEN}✅ Directories created${NC}"

# Generate sync script
echo -e "${BLUE}📝 Creating TwoFace sync script...${NC}"
cat > "$SCRIPT_DIR/twoface-sync.sh" << 'SYNC_SCRIPT_EOF'
#!/bin/bash

# TwoFace v1.0.0
# A file synchronization tool for dual-directory workflows with notifications

# Configuration - These will be updated by the installer
WRITE_DIR="__WRITE_DIR__"
DEPLOY_DIR="__DEPLOY_DIR__"
LOG_FILE="__LOG_FILE__"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

# Function to send macOS notification
send_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-Glass}"
    
    osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
}

# Function to sync a single file
sync_file() {
    local file_path="$1"
    local relative_path="${file_path#$WRITE_DIR/}"
    local deploy_file="$DEPLOY_DIR/$relative_path"
    local deploy_dir=$(dirname "$deploy_file")
    
    # Skip if file is this script or log file
    if [[ "$file_path" == *"twoface-sync.sh"* ]] || [[ "$file_path" == *"sync.log"* ]] || [[ "$file_path" == *".DS_Store"* ]]; then
        return
    fi
    
    # Create directory structure in deploy if it doesn't exist
    if [[ ! -d "$deploy_dir" ]]; then
        mkdir -p "$deploy_dir"
        log_message "Created directory: $deploy_dir"
    fi
    
    # Copy the file
    if cp "$file_path" "$deploy_file"; then
        log_message "✅ Synced: $relative_path"
        send_notification "TwoFace" "📁 $relative_path synced to deploy" "Glass"
    else
        log_message "❌ Failed to sync: $relative_path"
        send_notification "TwoFace Error" "⚠️ Failed to sync $relative_path" "Basso"
    fi
}

# Function to handle file deletion
handle_deletion() {
    local file_path="$1"
    local relative_path="${file_path#$WRITE_DIR/}"
    local deploy_file="$DEPLOY_DIR/$relative_path"
    
    if [[ -f "$deploy_file" ]]; then
        if rm "$deploy_file"; then
            log_message "🗑️ Deleted from deploy: $relative_path"
            send_notification "TwoFace" "🗑️ $relative_path removed from deploy" "Glass"
        else
            log_message "❌ Failed to delete from deploy: $relative_path"
        fi
    fi
}

# Function to perform initial sync
initial_sync() {
    log_message "🔄 Starting initial sync..."
    send_notification "TwoFace" "🔄 Initial sync starting" "Glass"
    
    # Create deploy directory if it doesn't exist
    if [[ ! -d "$DEPLOY_DIR" ]]; then
        mkdir -p "$DEPLOY_DIR"
        log_message "Created deploy directory: $DEPLOY_DIR"
    fi
    
    # Sync all files (excluding script and log files)
    find "$WRITE_DIR" -type f \( ! -name "twoface-sync.sh" ! -name "sync.log" ! -name ".DS_Store" \) -print0 | while IFS= read -r -d '' file; do
        sync_file "$file"
    done
    
    log_message "✅ Initial sync completed"
    send_notification "TwoFace" "✅ Initial sync completed" "Glass"
}

# Function to start watching for changes
start_watching() {
    log_message "👀 Starting file watcher for: $WRITE_DIR"
    send_notification "TwoFace" "👀 Monitoring $WRITE_DIR for changes" "Glass"
    
    # Check if fswatch is installed (use full path for LaunchAgent compatibility)
    FSWATCH_PATH="/usr/local/bin/fswatch"
    if [[ ! -x "$FSWATCH_PATH" ]]; then
        # Try alternative paths
        for path in "/opt/homebrew/bin/fswatch" "/usr/bin/fswatch"; do
            if [[ -x "$path" ]]; then
                FSWATCH_PATH="$path"
                break
            fi
        done
        
        # Fallback to PATH search
        if [[ ! -x "$FSWATCH_PATH" ]] && ! command -v fswatch &> /dev/null; then
            log_message "❌ fswatch not found"
            send_notification "TwoFace Error" "⚠️ fswatch not installed. Please run: brew install fswatch" "Basso"
            exit 1
        elif [[ ! -x "$FSWATCH_PATH" ]]; then
            FSWATCH_PATH="fswatch"
        fi
    fi
    
    # Use fswatch to monitor file changes
    "$FSWATCH_PATH" -r "$WRITE_DIR" | while read file; do
        # Skip if file is this script or log file
        if [[ "$file" == *"twoface-sync.sh"* ]] || [[ "$file" == *"sync.log"* ]] || [[ "$file" == *".DS_Store"* ]]; then
            continue
        fi
        
        if [[ -f "$file" ]]; then
            # File exists, sync it
            log_message "📝 File changed: ${file#$WRITE_DIR/}"
            sync_file "$file"
        else
            # File might have been deleted
            log_message "🗑️ File may have been deleted: ${file#$WRITE_DIR/}"
            handle_deletion "$file"
        fi
    done
}

# Main function
main() {
    # Create log file if it doesn't exist
    touch "$LOG_FILE"
    
    # Handle command line arguments
    case "${1:-}" in
        "init")
            initial_sync
            ;;
        "watch")
            start_watching
            ;;
        "sync")
            initial_sync
            start_watching
            ;;
        *)
            echo "Usage: $0 {init|watch|sync}"
            echo "  init  - Perform initial sync only"
            echo "  watch - Start file watcher only"
            echo "  sync  - Perform initial sync and start watching"
            exit 1
            ;;
    esac
}

# Trap to handle script termination
trap 'log_message "🛑 TwoFace stopped"; send_notification "TwoFace" "🛑 File synchronization stopped" "Glass"; exit 0' INT TERM

# Run main function
main "$@"
SYNC_SCRIPT_EOF

# Update placeholders in sync script
sed -i '' "s|__WRITE_DIR__|$WRITE_DIR|g" "$SCRIPT_DIR/twoface-sync.sh"
sed -i '' "s|__DEPLOY_DIR__|$DEPLOY_DIR|g" "$SCRIPT_DIR/twoface-sync.sh"
sed -i '' "s|__LOG_FILE__|$SCRIPT_DIR/sync.log|g" "$SCRIPT_DIR/twoface-sync.sh"

chmod +x "$SCRIPT_DIR/twoface-sync.sh"
echo -e "${GREEN}✅ TwoFace sync script created${NC}"

# Generate LaunchAgent plist
echo -e "${BLUE}📋 Creating LaunchAgent...${NC}"
PLIST_FILE="com.user.twoface.plist"
cat > "$SCRIPT_DIR/$PLIST_FILE" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.twoface</string>
    
    <key>Program</key>
    <string>$SCRIPT_DIR/twoface-sync.sh</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_DIR/twoface-sync.sh</string>
        <string>sync</string>
    </array>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>KeepAlive</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>$SCRIPT_DIR/sync-stdout.log</string>
    
    <key>StandardErrorPath</key>
    <string>$SCRIPT_DIR/sync-stderr.log</string>
    
    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR</string>
    
    <key>ThrottleInterval</key>
    <integer>1</integer>
</dict>
</plist>
PLIST_EOF

# Install LaunchAgent
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
if [[ ! -d "$LAUNCH_AGENTS_DIR" ]]; then
    mkdir -p "$LAUNCH_AGENTS_DIR"
fi

cp "$SCRIPT_DIR/$PLIST_FILE" "$LAUNCH_AGENTS_DIR/"
echo -e "${GREEN}✅ LaunchAgent installed${NC}"

# Load the launch agent
echo -e "${BLUE}🔄 Starting service...${NC}"
launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_FILE"
echo -e "${GREEN}✅ Service started${NC}"

# Generate uninstaller
echo -e "${BLUE}📝 Creating uninstaller...${NC}"
cat > "$SCRIPT_DIR/twoface-uninstall.sh" << UNINSTALL_EOF
#!/bin/bash

# TwoFace Uninstaller

echo "🗑️  Uninstalling TwoFace..."

# Stop and remove service
launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_FILE" 2>/dev/null || true
rm -f "$LAUNCH_AGENTS_DIR/$PLIST_FILE"

# Remove files (but keep write and deploy directories)
rm -f "$SCRIPT_DIR/twoface-sync.sh"
rm -f "$SCRIPT_DIR/$PLIST_FILE"
rm -f "$SCRIPT_DIR/sync.log"
rm -f "$SCRIPT_DIR/sync-stdout.log"
rm -f "$SCRIPT_DIR/sync-stderr.log"
rm -f "$SCRIPT_DIR/twoface-uninstall.sh"

echo "✅ TwoFace uninstalled successfully"
echo "Note: Your write and deploy directories were preserved"
UNINSTALL_EOF

chmod +x "$SCRIPT_DIR/twoface-uninstall.sh"
echo -e "${GREEN}✅ Uninstaller created${NC}"

echo
echo -e "${GREEN}🎉 TwoFace installation complete!${NC}"
echo
echo -e "${BLUE}📋 Installation Summary:${NC}"
echo "  • Write directory: $WRITE_DIR"
echo "  • Deploy directory: $DEPLOY_DIR"
echo "  • Log file: $SCRIPT_DIR/sync.log"
echo "  • Service will start automatically on login"
echo
echo -e "${BLUE}🛠️  Management Commands:${NC}"
echo "  • View logs:     tail -f $SCRIPT_DIR/sync.log"
echo "  • Stop service:  launchctl unload $LAUNCH_AGENTS_DIR/$PLIST_FILE"
echo "  • Start service: launchctl load $LAUNCH_AGENTS_DIR/$PLIST_FILE"
echo "  • Uninstall:     $SCRIPT_DIR/twoface-uninstall.sh"
echo
echo -e "${BLUE}🧪 Test the sync:${NC}"
echo "  1. Create a test file in $WRITE_DIR"
echo "  2. Save it and check if it appears in $DEPLOY_DIR"
echo "  3. You should see a notification when the sync happens"
echo
echo -e "${YELLOW}💡 TwoFace is now running and monitoring for changes!${NC}"
