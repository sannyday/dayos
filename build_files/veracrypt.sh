#!/bin/bash

# VeraCrypt installation script for Fedora
# Downloads, verifies PGP signature, and installs VeraCrypt RPM package
# Dynamically detects latest version

set -e  # Exit on any error

# Configuration variables
VERACRYPT_OFFICIAL_URL="https://veracrypt.io/en/Downloads.html"
VERACRYPT_GITHUB_API="https://api.github.com/repos/veracrypt/VeraCrypt/releases/latest"
VERACRYPT_KEY_URL="https://amcrypto.jp/VeraCrypt/VeraCrypt_PGP_public_key.asc"
EXPECTED_FINGERPRINT="5069 A233 D55A 0EEB 174A 5FC3 821A CD02 680D 16DE"
ARCH="x86_64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Function to extract version number from string
extract_version() {
    echo "$1" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

# Function to detect latest version
detect_latest_version() {
    print_status "Detecting latest VeraCrypt version..."

    # Try GitHub API first (usually has latest releases)
    local github_version=""
    if command -v curl &> /dev/null; then
        github_version=$(curl -s "$VERACRYPT_GITHUB_API" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4 | sed 's/^VeraCrypt version //')
    elif command -v wget &> /dev/null; then
        github_version=$(wget -qO- "$VERACRYPT_GITHUB_API" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4 | sed 's/^VeraCrypt version //')
    fi

    if [[ -n "$github_version" ]]; then
        VERSION=$(extract_version "$github_version")
        print_status "Detected version from GitHub: $VERSION"
        return 0
    fi

    # Fallback: Try to scrape official page
    print_warning "GitHub API unavailable, checking official website..."
    local official_content=""
    if command -v curl &> /dev/null; then
        official_content=$(curl -s "$VERACRYPT_OFFICIAL_URL" | grep -i "latest stable release")
    elif command -v wget &> /dev/null; then
        official_content=$(wget -qO- "$VERACRYPT_OFFICIAL_URL" | grep -i "latest stable release")
    fi

    if [[ -n "$official_content" ]]; then
        VERSION=$(extract_version "$official_content")
        if [[ -n "$VERSION" ]]; then
            print_status "Detected version from official website: $VERSION"
            return 0
        fi
    fi

    # If all detection methods fail, use hardcoded fallback
    print_warning "Could not auto-detect version, using fallback: 1.26.24"
    VERSION="1.26.24"
}

# Construct download URLs based on detected version
set_download_urls() {
    # Base URL for SourceForge (where VeraCrypt binaries are hosted)
    BASE_URL="https://sourceforge.net/projects/veracrypt/files/VeraCrypt%20$VERSION/Linux"

    # RPM package naming pattern (may need adjustment for different Fedora versions)
    # Note: VeraCrypt uses CentOS packages for Fedora compatibility
    RPM_PACKAGE="veracrypt-${VERSION}-Fedora-40-${ARCH}.rpm"
    
    # Alternative package names to try (VeraCrypt has used different naming schemes)
    RPM_PACKAGE_ALT1="veracrypt-${VERSION}-centos-8-${ARCH}.rpm"
    RPM_PACKAGE_ALT2="veracrypt-${VERSION}-fedora-${ARCH}.rpm"

    SIG_FILE="${RPM_PACKAGE}.sig"

    print_status "Using RPM package: $RPM_PACKAGE"
}

# Import VeraCrypt GPG public key
import_gpg_key() {
    print_status "Importing VeraCrypt GPG public key..."

    # Import the key using rpm (as recommended on the website)
    if ! rpm --import "$VERACRYPT_KEY_URL"; then
        print_error "Failed to import GPG key using rpm, trying alternative method..."

        # Alternative: Download and import using gpg
        if command -v gpg &> /dev/null; then
            wget -q "$VERACRYPT_KEY_URL" -O /tmp/veracrypt_key.asc
            gpg --import /tmp/veracrypt_key.asc 2>/dev/null
            rm -f /tmp/veracrypt_key.asc
            print_status "GPG key imported via gpg (alternative method)"
        else
            print_error "Failed to import GPG key. Please check your internet connection."
            print_error "You can manually import the key with: rpm --import $VERACRYPT_KEY_URL"
            exit 1
        fi
    else
        print_status "GPG key imported successfully via rpm"
    fi
}

# Download VeraCrypt RPM (try multiple package name patterns)
download_files() {
    print_status "Downloading VeraCrypt RPM package..."

    local download_success=false
    local package_to_use=""

    # Try different package naming patterns
    for pkg in "$RPM_PACKAGE" "$RPM_PACKAGE_ALT1" "$RPM_PACKAGE_ALT2"; do
        print_status "Trying package name: $pkg"

        # Download RPM
        if wget -q --show-progress "${BASE_URL}/${pkg}/download" -O "$pkg"; then
            # Download signature
            if wget -q --show-progress "${BASE_URL}/${pkg}.sig/download" -O "${pkg}.sig"; then
                package_to_use="$pkg"
                SIG_FILE="${pkg}.sig"
                download_success=true
                print_status "Successfully downloaded: $pkg"
                break
            else
                rm -f "$pkg"  # Clean up partial download
            fi
        fi
    done

    if [[ "$download_success" = false ]]; then
        print_error "Failed to download RPM package with any naming pattern."
        print_error "Available packages may be listed at: https://sourceforge.net/projects/veracrypt/files/"
        print_error "You may need to manually check the correct package name for your Fedora version."
        exit 1
    fi

    RPM_PACKAGE="$package_to_use"
}

# Verify the RPM signature
verify_signature() {
    print_status "Verifying RPM package signature..."

    # Check if rpm package is valid
    if ! rpm -K "$RPM_PACKAGE" 2>/dev/null; then
        print_error "RPM package appears to be corrupted or invalid"
        exit 1
    fi

    # Verify the signature using rpm's built-in verification
    VERIFICATION_OUTPUT=$(rpm -K "$RPM_PACKAGE" 2>&1)

    if echo "$VERIFICATION_OUTPUT" | grep -q "digests signatures OK"; then
        print_status "✓ RPM signature verification successful"
        echo "Verification details:"
        echo "$VERIFICATION_OUTPUT"

        # Display key fingerprint for manual verification
        echo ""
        print_status "Expected GPG key fingerprint: $EXPECTED_FINGERPRINT"
        print_status "During key import, you should have verified this fingerprint matches."
        return 0
    else
        print_error "RPM signature verification failed!"
        echo "Verification output:"
        echo "$VERIFICATION_OUTPUT"
        return 1
    fi
}

# Install the RPM package
install_veracrypt() {
    print_status "Installing VeraCrypt..."

    # Check dependencies
    print_status "Checking dependencies..."
    if ! rpm -q fuse fuse-libs &> /dev/null; then
        print_status "Installing required fuse packages..."
        dnf5 install -y fuse fuse-libs
    fi

    # Check for wxWidgets dependency (required for GUI)
    if ! rpm -q wxGTK3 &> /dev/null; then
        print_status "Installing wxGTK3 for GUI support..."
        dnf5 install -y wxGTK3
    fi

    # Install the RPM
    if rpm -ivh "$RPM_PACKAGE"; then
        print_status "✓ VeraCrypt installed successfully"
    else
        # Try upgrading if already installed
        print_status "Attempting upgrade..."
        if rpm -Uvh "$RPM_PACKAGE"; then
            print_status "✓ VeraCrypt upgraded successfully"
        else
            print_error "Failed to install/upgrade VeraCrypt"
            print_error "You might need to manually resolve dependencies or conflicts."
            exit 1
        fi
    fi
}

# Clean up downloaded files
cleanup() {
    print_status "Cleaning up downloaded files..."
    rm -f "$RPM_PACKAGE" "$SIG_FILE"
    print_status "Cleanup complete"
}

# Display success message
show_success() {
    echo ""
    echo "================================================"
    echo "VeraCrypt installation completed successfully!"
    echo "================================================"
    echo ""
    echo "Version: $VERSION"
    echo "Installed to: /usr/bin/veracrypt"
    echo ""
    echo "You can now launch VeraCrypt by:"
    echo "1. Searching for 'VeraCrypt' in your application menu"
    echo "2. Running 'veracrypt' from the terminal"
    echo ""
    echo "Important security notes:"
    echo "- The RPM package uses standard RPM signature mechanism"
    echo "- Always verify the fingerprint: ${EXPECTED_FINGERPRINT}"
    echo "- Your security is paramount"
    echo ""
}

# Main execution
main() {
    echo "================================================"
    echo "VeraCrypt Installation Script for Fedora"
    echo "Dynamic Version Detection"
    echo "================================================"
    echo ""

    # Detect latest version
    detect_latest_version

    # Set download URLs based on detected version
    set_download_urls

    # Create temporary directory for downloads
    WORK_DIR=$(mktemp -d)
    cd "$WORK_DIR"
    print_status "Working in temporary directory: $WORK_DIR"

    # Execute steps
    import_gpg_key
    download_files
    verify_signature

    # Only proceed if signature verification succeeded
    if [[ $? -eq 0 ]]; then
        install_veracrypt
        cleanup
        show_success
    else
        print_error "Signature verification failed. Installation aborted."
        print_error "Please verify you have the correct GPG key and try again."
        exit 1
    fi

    # Clean up temporary directory
    cd ..
    rm -rf "$WORK_DIR"
}

# Run the main function
main "$@"
