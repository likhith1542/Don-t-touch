# 🛡️ Don't Touch My Phone

A production-grade Flutter security app that detects unauthorized phone access and triggers loud alarms with intruder capture.

---

## 📱 Features

### 🔍 Motion Detection
- Real-time accelerometer + gyroscope monitoring via `sensors_plus`
- Auto-calibrates baseline when armed
- Rolling average smoothing to eliminate false positives
- **Sensitivity levels:** Low (18.0g), Medium (12.0g), High (7.0g)
- Debounce logic to prevent duplicate triggers (2s cooldown)

### 🚨 Alarm System
- 4 alarm tones: Siren, Beep, Scream, Horn
- Loops continuously until manually stopped
- Vibration pattern (500ms on / 200ms off)
- Flashlight strobe via `torch_light`
- Full-screen alarm UI that overrides normal app state

### 🔐 Security Lock
- 4-digit PIN required to disarm
- Optional biometric (fingerprint) auth via `local_auth`
- Wrong PIN → intruder selfie captured automatically
- Wrong attempt counter tracked

### 📸 Intruder Selfie
- Front camera capture on trigger
- Also captures on wrong PIN entry
- Saved locally to `AppDocumentsDir/intruder_logs/`
- Displayed in Intruder Log with timestamp

### ⏱️ Activation Delay
- Configurable delay: 5s / 10s / 15s / 30s
- Countdown orb displayed while arming
- Cancel button to abort arming

### 📊 Intruder Logs
- Full audit trail with timestamps
- Trigger type: Motion / Pickup / Wrong PIN
- Intruder photo display in-card
- Clear all logs with confirmation

### 🎨 UI/UX
- Dark-first design with space theme
- Animated status orb with pulse + scan line
- Real-time motion wave graph
- Smooth page transitions
- Onboarding with permission request flow

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.16+ (Dart 3.0+)
- Android SDK (min API 23 / Android 6.0)
- Physical Android device (sensors don't work on emulator)

### Installation

```bash
# 1. Clone or extract the project
cd dont_touch_my_phone

# 2. Install dependencies
flutter pub get

# 3. Connect your Android device (enable USB Debugging)
flutter devices

# 4. Run in debug mode
flutter run

# 5. Build release APK
flutter build apk --release
# APK at: build/app/outputs/flutter-apk/app-release.apk
```

### Install APK Directly

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 📦 Adding Alarm Sounds

Place your `.mp3` alarm files in `assets/sounds/`:

```
assets/sounds/
├── siren.mp3
├── beep_alarm.mp3
├── scream_alarm.mp3
└── horn_alarm.mp3
```

**Free sources:**
- [Freesound.org](https://freesound.org) – search "siren alarm"
- [Mixkit.co](https://mixkit.co/free-sound-effects/alarm/)
- [Zapsplat.com](https://www.zapsplat.com/sound-effect-category/alarms/)

---

## 🗂️ Project Structure

```
lib/
├── main.dart                    # App entry + Hive init
├── models/
│   ├── app_settings.dart        # Settings model (Hive)
│   ├── app_settings.g.dart      # Hive adapter (generated)
│   ├── intruder_log.dart        # Log model (Hive)
│   └── intruder_log.g.dart      # Hive adapter (generated)
├── services/
│   ├── protection_controller.dart  # Central state manager
│   ├── motion_detection_service.dart  # Accel + gyro
│   ├── alarm_service.dart       # Audio + vibration + flash
│   ├── camera_service.dart      # Intruder selfie
│   ├── background_service.dart  # Foreground service
│   └── permissions_service.dart # Permission handling
├── screens/
│   ├── onboarding_screen.dart   # First-launch flow
│   ├── home_screen.dart         # Main dashboard
│   ├── alarm_screen.dart        # Full-screen alarm UI
│   ├── settings_screen.dart     # App settings
│   └── intruder_logs_screen.dart # Log viewer
├── widgets/
│   ├── status_orb.dart          # Animated status orb
│   ├── pin_entry_widget.dart    # PIN numpad
│   ├── pattern_lock_widget.dart # Pattern draw
│   └── motion_wave_painter.dart # Real-time graph
└── utils/
    └── app_theme.dart           # Colors + typography
```

---

## ⚙️ Key Architecture Decisions

| Decision | Rationale |
|---|---|
| Singleton `ProtectionController` | Single source of truth across all screens |
| `ChangeNotifier` pattern | Simple reactive state without provider/bloc overhead |
| Hive for storage | Fast, typed, no SQL boilerplate |
| Sensor smoothing buffer | Eliminates false triggers on table vibrations |
| Debounce on triggers | Prevents alarm spam from rapid sensor readings |
| Calibration on arm | Adapts to current phone orientation |

---

## 🔋 Battery & Background Notes

- Uses `flutter_background_service` as an **Android Foreground Service**
- Foreground service keeps the process alive when screen is off
- Notification displayed while protection is active (required by Android)
- Request "Ignore Battery Optimizations" permission for maximum reliability
- On some MIUI/OxygenOS devices, manually allow autostart in phone settings

---

## 🧪 Testing Tips

1. **Test on a real device** — emulators have no real accelerometers
2. **Set sensitivity to "High"** for testing (lower threshold)
3. **Reduce activation delay to 5s** during development
4. **Watch the motion wave graph** on the home screen while protected
5. **Test wrong PIN** to verify intruder photo capture

---

## 🔧 Known Limitations

| Limitation | Workaround |
|---|---|
| Audio may be muted in silent mode | Android 8+ restricts overriding silence; encourage user to set alarm volume |
| Flashlight unavailable on some devices | Graceful fallback — no crash |
| Biometric varies by device | Falls back to PIN only |
| Background killed on aggressive ROMs | Show user a guide to whitelist the app |

---

## 📋 Permissions Required

| Permission | Purpose |
|---|---|
| `CAMERA` | Intruder selfie capture |
| `VIBRATE` | Haptic alarm |
| `FOREGROUND_SERVICE` | Background monitoring |
| `POST_NOTIFICATIONS` | Active protection notification |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Prevent background kill |
| `WAKE_LOCK` | Keep CPU active when screen off |
| `USE_BIOMETRIC` | Fingerprint unlock |
| `MODIFY_AUDIO_SETTINGS` | Alarm volume control |

---

## 🛠️ Building for Release

```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore ~/dont-touch.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias dont-touch

# Create key.properties in android/
cat > android/key.properties << EOF
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=dont-touch
storeFile=/path/to/dont-touch.jks
EOF

# Build release APK
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# Build App Bundle for Play Store
flutter build appbundle --release
```

---

## 📄 License

MIT License — free to use, modify, and ship.