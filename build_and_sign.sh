#!/bin/bash
# =============================================================
#  Don't Touch My Phone — Build & Sign Script
#  Run from project root: bash build_and_sign.sh
# =============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
CYAN='\033[0;36m'
NC='\033[0m'

KEYSTORE_PATH="$HOME/.android/dont-touch-my-phone.jks"
KEY_ALIAS="dont-touch"
KEY_PROPS="android/key.properties"

echo ""
echo -e "${BOLD}🛡️  Don't Touch My Phone — Build & Sign${NC}"
echo "============================================"
echo ""

# ── Step 1: Check Flutter ──────────────────────────────────
if ! command -v flutter &> /dev/null; then
  echo -e "${RED}❌ Flutter not found. Install from https://docs.flutter.dev/get-started/install${NC}"
  exit 1
fi
echo -e "${GREEN}✅ Flutter:${NC} $(flutter --version 2>&1 | head -1)"

# ── Step 2: Check / Create Keystore ───────────────────────
echo ""
echo -e "${BOLD}Step 1 — Keystore${NC}"

if [ -f "$KEYSTORE_PATH" ]; then
  echo -e "${GREEN}✅ Keystore already exists:${NC} $KEYSTORE_PATH"
else
  echo -e "${YELLOW}No keystore found. Creating one now...${NC}"
  echo ""
  echo -e "${CYAN}You'll be prompted for:${NC}"
  echo "  • Keystore password (remember this!)"
  echo "  • Key password (can be same as keystore password)"
  echo "  • Your name / org / location (can be anything)"
  echo ""

  mkdir -p "$HOME/.android"
  keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$KEY_ALIAS"

  echo ""
  echo -e "${GREEN}✅ Keystore created at:${NC} $KEYSTORE_PATH"
fi

# ── Step 3: Write key.properties ──────────────────────────
echo ""
echo -e "${BOLD}Step 2 — key.properties${NC}"

if [ -f "$KEY_PROPS" ]; then
  echo -e "${GREEN}✅ key.properties already exists — skipping.${NC}"
else
  echo -e "${YELLOW}Enter your keystore password:${NC}"
  read -s STORE_PASS
  echo ""
  echo -e "${YELLOW}Enter your key password (press Enter if same as keystore):${NC}"
  read -s KEY_PASS
  echo ""
  [ -z "$KEY_PASS" ] && KEY_PASS="$STORE_PASS"

  cat > "$KEY_PROPS" << EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=$KEY_ALIAS
storeFile=$KEYSTORE_PATH
EOF

  echo -e "${GREEN}✅ android/key.properties created${NC}"
  echo -e "${YELLOW}⚠️  This file contains passwords — never commit it to git!${NC}"
fi

# ── Step 4: Patch build.gradle.kts to use key.properties ──
echo ""
echo -e "${BOLD}Step 3 — Wiring signing config into build.gradle.kts${NC}"

BUILD_GRADLE="android/app/build.gradle.kts"

if grep -q "key.properties" "$BUILD_GRADLE" 2>/dev/null; then
  echo -e "${GREEN}✅ build.gradle.kts already has signing config${NC}"
else
  echo -e "${YELLOW}Patching $BUILD_GRADLE...${NC}"

  # Create a patched version
  python3 - << 'PY'
import re

path = "android/app/build.gradle.kts"
with open(path, "r") as f:
    content = f.read()

# Insert keystore loading block before android { ... }
keystore_block = '''
import java.util.Properties
import java.io.FileInputStream

val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''

signing_config = '''
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
'''

# Add import before plugins block
if "import java.util.Properties" not in content:
    content = keystore_block + content

# Add signingConfigs block inside android { before buildTypes
if "signingConfigs" not in content:
    content = content.replace(
        "    buildTypes {",
        signing_config + "\n    buildTypes {"
    )

# Update release buildType to use our signing config
content = content.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("release")'
)

with open(path, "w") as f:
    f.write(content)

print("  Patched successfully")
PY
  echo -e "${GREEN}✅ build.gradle.kts patched with release signing config${NC}"
fi

# ── Step 5: Clean ──────────────────────────────────────────
echo ""
echo -e "${BOLD}Step 4 — Clean${NC}"
flutter clean
echo -e "${GREEN}✅ Clean done${NC}"

# ── Step 6: Get packages ───────────────────────────────────
echo ""
echo -e "${BOLD}Step 5 — Install packages${NC}"
flutter pub get
echo -e "${GREEN}✅ Packages ready${NC}"

# ── Step 7: Build ──────────────────────────────────────────
echo ""
echo -e "${BOLD}Step 6 — Choose build target${NC}"
echo ""
echo "  1) APK — install directly on device via adb / file manager"
echo "  2) App Bundle (.aab) — for Google Play Store upload"
echo "  3) Both"
echo ""
read -p "Choice [1-3]: " BUILD_CHOICE

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
AAB_PATH="build/app/outputs/bundle/release/app-release.aab"

case $BUILD_CHOICE in
  1|"")
    echo ""
    echo -e "${BLUE}🔨 Building release APK...${NC}"
    flutter build apk --release --obfuscate --split-debug-info=build/debug-info
    echo ""
    echo -e "${GREEN}✅ APK built!${NC}"
    echo -e "   📦 ${BOLD}$APK_PATH${NC}"
    echo ""
    echo -e "${CYAN}Install on connected device:${NC}"
    echo -e "   adb install $APK_PATH"
    echo ""
    echo -e "${CYAN}Or copy APK to phone and open it (enable 'Install Unknown Apps' first)${NC}"
    ;;
  2)
    echo ""
    echo -e "${BLUE}🔨 Building App Bundle...${NC}"
    flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
    echo ""
    echo -e "${GREEN}✅ App Bundle built!${NC}"
    echo -e "   📦 ${BOLD}$AAB_PATH${NC}"
    echo ""
    echo -e "${CYAN}Upload this .aab to Google Play Console → Production / Internal Testing${NC}"
    ;;
  3)
    echo ""
    echo -e "${BLUE}🔨 Building APK...${NC}"
    flutter build apk --release --obfuscate --split-debug-info=build/debug-info
    echo -e "${GREEN}✅ APK: $APK_PATH${NC}"

    echo ""
    echo -e "${BLUE}🔨 Building App Bundle...${NC}"
    flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
    echo -e "${GREEN}✅ AAB: $AAB_PATH${NC}"
    ;;
esac

# ── Step 8: Verify signature ───────────────────────────────
if [ -f "$APK_PATH" ] && command -v apksigner &> /dev/null; then
  echo ""
  echo -e "${BOLD}Step 7 — Verifying APK signature${NC}"
  apksigner verify --verbose "$APK_PATH" 2>&1 | grep -E "Verified|signer"
  echo -e "${GREEN}✅ Signature verified${NC}"
fi

echo ""
echo -e "${BOLD}${GREEN}🎉 All done!${NC}"
echo ""
echo -e "${YELLOW}Important reminders:${NC}"
echo "  🔑 Back up your keystore: $KEYSTORE_PATH"
echo "  🔑 Back up android/key.properties (passwords)"
echo "  🚫 Never commit key.properties or .jks to git"
echo "  📋 Keep your passwords in a password manager"
echo ""