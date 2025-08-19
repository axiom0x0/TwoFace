![TwoFace](TwoFace.png)

# TwoFace 🎭

A file synchronization tool for dual-directory workflows with macOS notifications.

Perfect for developers who need to maintain separate Git accounts for personal development and public deployment.

## 🚀 Quick Start

```bash
# Clone or download TwoFace
git clone https://github.com/yourusername/twoface.git
cd twoface

# Run the installer
chmod +x twoface-installer.sh
./twoface-installer.sh
```

Follow the prompts to set up your directories, or accept the defaults:
- **Base directory**: `~/code`
- **Write directory**: `~/code/write` (for development)
- **Deploy directory**: `~/code/deploy` (for publishing)

## 🎯 Use Case

TwoFace is designed for the common developer workflow where you need to:

1. **Develop** with your personal Git account in one directory
2. **Deploy/Publish** with a different Git account in another directory
3. **Sync changes automatically** between the two directories
4. **Get notifications** when files are synchronized

## ✨ Features

- **Real-time file synchronization** between write and deploy directories
- **macOS notifications** for all sync operations
- **Automatic startup** on login via LaunchAgent
- **Smart filtering** excludes system files and TwoFace infrastructure
- **Comprehensive logging** with timestamps
- **Easy installation** with interactive installer
- **Clean uninstallation** when needed

## 📋 Requirements

- macOS (tested on macOS 10.14+)
- Homebrew (will be installed if needed)
- `fswatch` (automatically installed via Homebrew)

## 🛠️ How It Works

1. **Monitor**: TwoFace watches your write directory for any file changes
2. **Sync**: When files are saved, they're immediately copied to the deploy directory
3. **Notify**: You get a notification confirming the sync operation
4. **Maintain**: Directory structure is preserved, deletions are handled

## 📁 Example Workflow

```
~/code/
├── twoface-sync.sh          # TwoFace executable
├── write/                   # Your development directory
│   ├── .git/               # Personal Git account
│   ├── project.py
│   └── README.md
└── deploy/                  # Auto-synced deployment directory
    ├── .git/               # Work/public Git account  
    ├── project.py          # ← Automatically synced
    └── README.md           # ← Automatically synced
```

## 🔧 Management Commands

```bash
# View sync logs
tail -f ~/code/sync.log

# Stop TwoFace service
launchctl unload ~/Library/LaunchAgents/com.user.twoface.plist

# Start TwoFace service
launchctl load ~/Library/LaunchAgents/com.user.twoface.plist

# Check if TwoFace is running
launchctl list | grep com.user.twoface

# Uninstall TwoFace
~/code/twoface-uninstall.sh
```

## 🧪 Testing the Installation

1. Create a test file in your write directory:
   ```bash
   echo "Hello TwoFace!" > ~/code/write/test.txt
   ```

2. Check if it appears in deploy directory:
   ```bash
   cat ~/code/deploy/test.txt
   ```

3. You should see a notification confirming the sync!

## 🛡️ What Gets Synced

**Synced:**
- All files and directories in your write directory
- Directory structure is maintained
- File permissions are preserved

**Not Synced:**
- TwoFace infrastructure files
- `.DS_Store` files
- System hidden files

## 🗑️ Uninstalling

TwoFace includes a clean uninstaller that removes all components while preserving your write and deploy directories:

```bash
~/code/twoface-uninstall.sh
```

## 🤝 Contributing

Issues and pull requests welcome! TwoFace is designed to be simple, reliable, and useful for dual-account Git workflows.

## 📄 License

MIT License

---

Created for developers who juggle multiple Git identities and need seamless file synchronization.


