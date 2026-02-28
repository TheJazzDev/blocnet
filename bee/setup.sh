#!/bin/bash

# BEE ML Service Setup Script
# Automates installation and configuration

set -e

usage() {
    echo "Usage: ./setup.sh [options]"
    echo ""
    echo "Options:"
    echo "  --with-embeddings   Install optional embeddings stack (sentence-transformers/torch)"
    echo "  --with-dev          Install development dependencies (pytest/black)"
    echo "  --full              Install runtime + embeddings + dev dependencies"
    echo "  --skip-install      Skip pip install steps (reuse existing environment)"
    echo "  --help              Show this help message"
    echo ""
}

INSTALL_RUNTIME=true
INSTALL_EMBEDDINGS=false
INSTALL_DEV=false
SKIP_INSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --with-embeddings)
            INSTALL_EMBEDDINGS=true
            shift
            ;;
        --with-dev)
            INSTALL_DEV=true
            shift
            ;;
        --full)
            INSTALL_EMBEDDINGS=true
            INSTALL_DEV=true
            shift
            ;;
        --skip-install)
            SKIP_INSTALL=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo ""
            usage
            exit 1
            ;;
    esac
done

echo "🐝 BEE ML Service Setup"
echo "======================="
echo ""

# Check Python version
echo "Checking Python version..."
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "✓ Python $python_version"
echo ""

# Create virtual environment
echo "Creating virtual environment..."
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi
echo ""

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate
echo "✓ Virtual environment activated"
echo ""

# Install dependencies
if [ "$SKIP_INSTALL" = true ]; then
    echo "Skipping dependency installation (--skip-install)"
else
    echo "Installing Python dependencies..."
    pip install --upgrade pip

    if [ "$INSTALL_RUNTIME" = true ]; then
        echo "→ Installing runtime dependencies"
        pip install -r requirements-runtime.txt
    fi

    if [ "$INSTALL_EMBEDDINGS" = true ]; then
        echo "→ Installing optional embeddings dependencies"
        pip install -r requirements-embeddings.txt
    fi

    if [ "$INSTALL_DEV" = true ]; then
        echo "→ Installing optional development dependencies"
        pip install -r requirements-dev.txt
    fi

    echo "✓ Dependencies installed"
fi
echo ""

# Setup environment file
if [ ! -f ".env" ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "✓ .env file created"
    echo "⚠️  Please edit .env and add your API keys"
else
    echo "✓ .env file already exists"
fi
echo ""

# Check for Ollama
echo "Checking for Ollama..."
if command -v ollama &> /dev/null; then
    echo "✓ Ollama is installed"

    # Check if models are pulled
    echo ""
    echo "Checking Ollama models..."
    if ollama list | grep -q "llama3.3"; then
        echo "✓ llama3.3 model found"
    else
        echo "⚠️  llama3.3 model not found"
        echo "   To install: ollama pull llama3.3:70b"
    fi

    if ollama list | grep -q "nomic-embed-text"; then
        echo "✓ nomic-embed-text model found"
    else
        echo "⚠️  nomic-embed-text model not found"
        echo "   To install: ollama pull nomic-embed-text"
    fi
else
    echo "⚠️  Ollama not installed"
    echo "   To install: curl https://ollama.ai/install.sh | sh"
fi
echo ""

echo "======================="
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit .env and configure your providers"
echo "2. (Optional) Install Ollama and pull models"
echo "3. Activate venv in your shell: source venv/bin/activate"
echo "4. Run: python -m app.main"
echo "5. Visit: http://localhost:8083/docs"
echo ""
echo "For detailed instructions, see README.md"
