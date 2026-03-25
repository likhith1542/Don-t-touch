#!/bin/bash
# =============================================================
#  Don't Touch My Phone — Setup Script
#  Run this after extracting the project
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BOLD}🛡️  Don't Touch My Phone — Setup${NC}"
echo "============================================"
echo ""

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter not found. Please install Flutter first.${NC}"
    echo "   https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo -e "${GREEN}✅ Flutter found:${NC} $(flutter --version | head -1)"
echo ""

# Check for connected devices
echo -e "${BLUE}📱 Checking for connected devices...${NC}"
DEVICES=$(flutter devices 2>&1)
echo "$DEVICES"
echo ""

# Install dependencies
echo -e "${BLUE}📦 Installing dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Check for asset sounds
echo -e "${BLUE}🔊 Checking alarm sound assets...${NC}"
SOUNDS_DIR="assets/sounds"
REQUIRED_SOUNDS=("siren.mp3" "beep_alarm.mp3" "scream_alarm.mp3" "horn_alarm.mp3")
MISSING=0

for sound in "${REQUIRED_SOUNDS[@]}"; do
    if [ ! -f "$SOUNDS_DIR/$sound" ]; then
        echo -e "  ${YELLOW}⚠️  Missing: $sound${NC}"
        MISSING=1
    else
        echo -e "  ${GREEN}✅ Found: $sound${NC}"
    fi
done

if [ $MISSING -eq 1 ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Some alarm sounds are missing.${NC}"
    echo "   Add .mp3 files to: assets/sounds/"
    echo "   Free sources:"
    echo "   • https://freesound.org (search: alarm)"
    echo "   • https://mixkit.co/free-sound-effects/alarm/"
    echo ""
    echo -e "${YELLOW}Creating placeholder files so app compiles...${NC}"
    for sound in "${REQUIRED_SOUNDS[@]}"; do
        if [ ! -f "$SOUNDS_DIR/$sound" ]; then
            # Create empty placeholder
            touch "$SOUNDS_DIR/$sound"
            echo -e "  Created placeholder: $sound"
        fi
    done
fi

echo ""

# Build options
echo -e "${BOLD}🚀 Ready to build! Choose an option:${NC}"
echo ""
echo "  1) Debug run (connected device/emulator)"
echo "  2) Build release APK"
echo "  3) Build App Bundle (Play Store)"
echo "  4) Skip — I'll run manually"
echo ""
read -p "Choice [1-4]: " CHOICE

case $CHOICE in
    1)
        echo ""
        echo -e "${BLUE}🏃 Running in debug mode...${NC}"
        flutter run
        ;;
    2)
        echo ""
        echo -e "${BLUE}🔨 Building release APK...${NC}"
        flutter build apk --release
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
        echo ""
        echo -e "${GREEN}✅ APK built successfully!${NC}"
        echo -e "   Location: ${BOLD}$APK_PATH${NC}"
        echo ""
        echo "   Install with:"
        echo -e "   ${BLUE}adb install $APK_PATH${NC}"
        ;;
    3)
        echo ""
        echo -e "${BLUE}🔨 Building App Bundle...${NC}"
        flutter build appbundle --release
        echo -e "${GREEN}✅ App Bundle built!${NC}"
        echo "   Location: build/app/outputs/bundle/release/app-release.aab"
        ;;
    4)
        echo ""
        echo -e "${GREEN}✅ Setup complete! Run manually with:${NC}"
        echo -e "   ${BLUE}flutter run${NC}  (debug)"
        echo -e "   ${BLUE}flutter build apk --release${NC}  (release APK)"
        ;;
    *)
        echo -e "${YELLOW}Skipping build step.${NC}"
        ;;
esac

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo -e "📖 See README.md for full documentation"
echo -e "🐛 Issues? Check: flutter doctor -v"
echo ""
