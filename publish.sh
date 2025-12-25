#!/bin/bash
# Publish script for regex-recipes PyPI package
# This script builds and publishes the package to PyPI

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the correct directory
if [ ! -f "pyproject.toml" ]; then
    print_error "pyproject.toml not found. Are you in the project root?"
    exit 1
fi

# Parse command line arguments
TARGET="pypi"
SKIP_TESTS=false
SKIP_BUILD_CLEAN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --test)
            TARGET="testpypi"
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-clean)
            SKIP_BUILD_CLEAN=true
            shift
            ;;
        --help)
            echo "Usage: ./publish.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --test          Upload to TestPyPI instead of PyPI"
            echo "  --skip-tests    Skip running tests before publishing"
            echo "  --skip-clean    Skip cleaning build artifacts before building"
            echo "  --help          Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

print_info "Publishing to ${TARGET}..."

# Check if required tools are installed
print_info "Checking required tools..."
if ! command -v python3 &> /dev/null; then
    print_error "python3 is not installed"
    exit 1
fi

if ! python3 -c "import build" &> /dev/null; then
    print_warning "build module not found. Installing..."
    pip install build
fi

if ! python3 -c "import twine" &> /dev/null; then
    print_warning "twine module not found. Installing..."
    pip install twine
fi

# Run tests (unless skipped)
if [ "$SKIP_TESTS" = false ]; then
    print_info "Running tests..."
    if command -v pytest &> /dev/null; then
        python3 -m pytest tests/ || {
            print_error "Tests failed. Fix tests before publishing."
            exit 1
        }
        print_success "All tests passed!"
    else
        print_warning "pytest not found. Skipping tests."
    fi
else
    print_warning "Skipping tests as requested."
fi

# Clean previous builds (unless skipped)
if [ "$SKIP_BUILD_CLEAN" = false ]; then
    print_info "Cleaning previous build artifacts..."
    rm -rf build/
    rm -rf dist/
    rm -rf *.egg-info
    print_success "Build artifacts cleaned."
else
    print_warning "Skipping clean as requested."
fi

# Build the package
print_info "Building package..."
python3 -m build || {
    print_error "Build failed."
    exit 1
}
print_success "Package built successfully!"

# Check the distribution
print_info "Checking distribution..."
python3 -m twine check dist/* || {
    print_error "Distribution check failed."
    exit 1
}
print_success "Distribution check passed!"

# Upload to PyPI or TestPyPI
if [ "$TARGET" = "testpypi" ]; then
    print_info "Uploading to TestPyPI..."
    python3 -m twine upload --repository testpypi dist/* || {
        print_error "Upload to TestPyPI failed."
        exit 1
    }
    print_success "Package uploaded to TestPyPI successfully!"
    print_info "Install with: pip install --index-url https://test.pypi.org/simple/ regex-recipes"
else
    print_info "Uploading to PyPI..."
    python3 -m twine upload dist/* || {
        print_error "Upload to PyPI failed."
        exit 1
    }
    print_success "Package uploaded to PyPI successfully!"
    print_info "Install with: pip install regex-recipes"
fi

print_success "🎉 Publishing complete!"
