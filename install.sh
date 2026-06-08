#!/bin/bash

# Installation script for SnapWiz - The Magical Package Installer
# This script sets up the application and creates a desktop entry

set -e

echo "======================================"
echo "⚡🧙‍♂️ SnapWiz - Setup"
echo "======================================"
echo ""
echo "Install packages in a snap, like a wizard!"
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed."
    echo "Please install Python 3.6 or higher and try again."
    exit 1
fi

echo "✓ Python 3 found: $(python3 --version)"

# Check if the stdlib venv module is available. If not, try to install a suitable package
# or fall back to installing virtualenv via pip. This handles Fedora (dnf) and other distros.
echo "Checking for Python venv support..."
if ! python3 -c "import venv" &> /dev/null; then
    echo "⚠ Warning: Python 'venv' module is not available. Attempting to install system packages..."

    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y python3-venv python3-pip || true
    elif command -v dnf &> /dev/null; then
        # Fedora/RHEL: try packages that provide virtualenv/venv functionality
        sudo dnf install -y python3-virtualenv python3-pip python3-devel || sudo dnf install -y python3-virtualenv python3-pip || true
    elif command -v yum &> /dev/null; then
        sudo yum install -y python3-virtualenv python3-pip || true
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm python-virtualenv python-pip || true
    else
        echo "Could not detect package manager to install venv. Will try pip fallback."
    fi

    # Re-check for stdlib venv
    if python3 -c "import venv" &> /dev/null; then
        echo "✓ Python 'venv' module is now available"
    else
        echo "⚠ Python 'venv' still not available. Will try installing virtualenv via pip and use it to create environments."
        # Ensure pip is available
        if ! command -v pip3 &> /dev/null; then
            if command -v python3 &> /dev/null; then
                python3 -m ensurepip --upgrade || true
            fi
        fi

        python3 -m pip install --user virtualenv || true
        if python3 -c "import virtualenv" &> /dev/null; then
            echo "✓ virtualenv installed via pip"
            USE_VIRTUALENV=1
        else
            echo "Error: Could not enable venv or virtualenv. Please install 'python3-venv' (Debian/Ubuntu) or 'python3-virtualenv' (Fedora) and re-run this script."
            exit 1
        fi
    fi
else
    echo "✓ Python 'venv' module available"
fi

# Get the current directory
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create virtual environment
VENV_DIR="$INSTALL_DIR/venv"
echo ""
echo "Creating virtual environment..."

if [ -d "$VENV_DIR" ]; then
    echo "⚠ Virtual environment already exists, recreating..."
    rm -rf "$VENV_DIR"
fi

# Create the virtual environment. Prefer stdlib venv, otherwise virtualenv.
if [ -z "$USE_VIRTUALENV" ]; then
    python3 -m venv "$VENV_DIR" || {
        echo "✗ Failed to create virtual environment with 'venv'."
        exit 1
    }
else
    python3 -m virtualenv -p "$(command -v python3)" "$VENV_DIR" || {
        echo "✗ Failed to create virtual environment with 'virtualenv'."
        exit 1
    }
fi

echo "✓ Virtual environment created at: $VENV_DIR"

# Activate virtual environment and install dependencies
echo ""
echo "Installing Python dependencies in virtual environment..."

# Use the venv's pip directly
"$VENV_DIR/bin/pip" install --upgrade pip
"$VENV_DIR/bin/pip" install -r requirements.txt

if [ $? -eq 0 ]; then
    echo "✓ Dependencies installed successfully"
else
    echo "✗ Failed to install dependencies"
    exit 1
fi

# Initialize app.sh launcher script
echo ""
echo "Initializing app.sh launcher script..."

APP_LAUNCHER="$INSTALL_DIR/app.sh"

cat > "$APP_LAUNCHER" << 'EOF'
#!/bin/bash

# SnapWiz - The Magical Package Installer
# Application launcher script

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set virtual environment path
VENV_DIR="$SCRIPT_DIR/venv"

# Check if virtual environment exists
if [ ! -f "$VENV_DIR/bin/python" ]; then
    echo "Error: Virtual environment not found."
    echo "Please run install.sh first to set up the application."
    exit 1
fi

# Run the application
cd "$SCRIPT_DIR"
exec "$VENV_DIR/bin/python" "$SCRIPT_DIR/main.py" "$@"
EOF

chmod +x "$APP_LAUNCHER"
echo "✓ Created app.sh launcher at: $APP_LAUNCHER"

# Make main.py executable
chmod +x main.py
echo "✓ Made main.py executable"

# Create desktop entry
DESKTOP_FILE="$HOME/.local/share/applications/snapwiz.desktop"
mkdir -p "$HOME/.local/share/applications"

echo ""
echo "Creating desktop entry..."

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=SnapWiz
Comment=Install packages in a snap, like a wizard!
Exec="$VENV_DIR/bin/python" "$INSTALL_DIR/main.py"
Icon=package-x-generic
Terminal=false
Type=Application
Categories=System;PackageManager;
EOF
 
if [ $? -eq 0 ]; then
    # Fix Exec line to remove embedded quotes which can break .desktop parsing
    sed -i "s|Exec=\"$VENV_DIR/bin/python\" \"$INSTALL_DIR/main.py\"|Exec=$VENV_DIR/bin/python $INSTALL_DIR/main.py|" "$DESKTOP_FILE" 2>/dev/null || true
    chmod +x "$DESKTOP_FILE"
    echo "✓ Desktop entry created at: $DESKTOP_FILE"
else
    echo "✗ Failed to create desktop entry"
fi

# Create a launcher script in user's bin directory
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

LAUNCHER="$BIN_DIR/snapwiz"

echo ""
echo "Creating launcher script..."

cat > "$LAUNCHER" << 'EOF'
#!/bin/bash
# SnapWiz Launcher Script
# This script ensures proper execution from any directory

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Detect the installation directory
if [ -f "$HOME/.snapwiz/install_path.txt" ]; then
    INSTALL_DIR=$(cat "$HOME/.snapwiz/install_path.txt")
else
    echo "Error: Installation path not found."
    echo "Please reinstall the application using install.sh"
    exit 1
fi

# Check if installation directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Error: Installation directory not found: $INSTALL_DIR"
    echo "Please reinstall the application."
    exit 1
fi

# Set virtual environment path
VENV_DIR="$INSTALL_DIR/venv"

# Check if virtual environment exists
if [ ! -f "$VENV_DIR/bin/python" ]; then
    echo "Error: Virtual environment not found at: $VENV_DIR"
    echo "Please reinstall the application using install.sh"
    exit 1
fi

# Run the application
cd "$INSTALL_DIR"
exec "$VENV_DIR/bin/python" "$INSTALL_DIR/main.py" "$@"
EOF
 

chmod +x "$LAUNCHER"
echo "✓ Created launcher script at: $LAUNCHER"

# Save installation path for launcher script
mkdir -p "$HOME/.snapwiz"
echo "$INSTALL_DIR" > "$HOME/.snapwiz/install_path.txt"

# Check if .local/bin is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo ""
    echo "⚠ Warning: $BIN_DIR is not in your PATH"
    echo "Add the following line to your ~/.bashrc or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Ask if user wants to set up testing
echo ""
echo "======================================"
echo "🧪 Test Setup (Optional)"
echo "======================================"
echo ""
read -p "Do you want to install test dependencies? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing test dependencies..."
    
    # Install test dependencies
    "$VENV_DIR/bin/pip" install coverage pytest pytest-cov
    
    if [ $? -eq 0 ]; then
        echo "✓ Test dependencies installed"
        
        # Ask if user wants to run tests
        echo ""
        read -p "Do you want to run tests now? (y/n) " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo ""
            echo "Running tests..."
            echo ""
            
            cd "$INSTALL_DIR"
            "$VENV_DIR/bin/python" -m test.run_tests
            
            TEST_RESULT=$?
            
            if [ $TEST_RESULT -eq 0 ]; then
                echo ""
                echo "✅ All tests passed!"
            else
                echo ""
                echo "⚠ Some tests failed. Check the output above."
            fi
        fi
    else
        echo "✗ Failed to install test dependencies"
    fi
else
    echo "Skipping test setup."
    echo "To run tests later, install dependencies:"
    echo "  $VENV_DIR/bin/pip install coverage pytest pytest-cov"
    echo "Then run:"
    echo "  $VENV_DIR/bin/python -m test.run_tests"
fi

echo ""
echo "======================================"
echo "⚡ Installation Complete! 🧙‍♂️"
echo "======================================"
echo ""
echo "You can now run SnapWiz by:"
echo "  1. Running: $VENV_DIR/bin/python $INSTALL_DIR/main.py"
echo "  2. Running: snapwiz (if ~/.local/bin is in PATH)"
echo "  3. Searching for 'SnapWiz' in your application menu"
echo ""
echo "To run tests:"
echo "  $VENV_DIR/bin/python -m test.run_tests"
echo ""
echo "To view test documentation:"
echo "  cat test/TESTING_GUIDE.md"
echo ""
echo "Note: The application uses a virtual environment at: $VENV_DIR"
echo ""
echo "Enjoy using SnapWiz - Install packages in a snap, like a wizard!"
echo ""
