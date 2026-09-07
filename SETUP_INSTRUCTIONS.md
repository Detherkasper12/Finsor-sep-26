# Finsor App Setup Instructions

## Prerequisites Installation

### 1. Install Flutter SDK

#### For Windows:
1. **Download Flutter SDK**
   - Go to [Flutter Windows Install](https://docs.flutter.dev/get-started/install/windows)
   - Download the latest stable release ZIP file
   - Extract to `C:\flutter` (or another location)

2. **Add Flutter to PATH**
   - Open System Properties → Advanced → Environment Variables
   - Under "User variables", find "Path" and click Edit
   - Add `C:\flutter\bin` to the PATH
   - Click OK and restart your terminal

3. **Verify Installation**
   ```bash
   flutter --version
   flutter doctor
   ```

#### For macOS:
1. **Download Flutter SDK**
   ```bash
   cd ~/development
   wget https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_3.16.0-stable.zip
   unzip flutter_macos_arm64_3.16.0-stable.zip
   ```

2. **Add to PATH**
   ```bash
   echo 'export PATH="$PATH:`pwd`/flutter/bin"' >> ~/.zshrc
   source ~/.zshrc
   ```

### 2. Install Android Studio

1. **Download Android Studio**
   - Go to [Android Studio](https://developer.android.com/studio)
   - Download and install

2. **Install Android SDK**
   - Open Android Studio
   - Go to Tools → SDK Manager
   - Install latest Android SDK (API 33+)
   - Accept licenses: `flutter doctor --android-licenses`

### 3. Install VS Code (Optional but Recommended)

1. **Download VS Code**
   - Go to [VS Code](https://code.visualstudio.com/)
   - Install Flutter and Dart extensions

## Project Setup

### 1. Navigate to Project Directory
```bash
cd C:\Users\abrek_otvjrzk\StudioProjects\Finsor
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Code
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### 4. Check Flutter Setup
```bash
flutter doctor
```

### 5. Connect Device or Start Emulator
```bash
# List available devices
flutter devices

# Start Android emulator (if installed)
flutter emulators
flutter emulators --launch <emulator_id>
```

### 6. Run the App
```bash
flutter run
```

## Firebase Configuration

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project named "finsor"
3. Enable Google Analytics (optional)

### 2. Add Android App
1. Click "Add app" → Android
2. Package name: `com.example.finsor`
3. Download `google-services.json`
4. Place in `android/app/` directory

### 3. Add iOS App (if targeting iOS)
1. Click "Add app" → iOS
2. Bundle ID: `com.example.finsor`
3. Download `GoogleService-Info.plist`
4. Place in `ios/Runner/` directory

### 4. Enable Authentication
1. Go to Authentication → Sign-in method
2. Enable "Email/Password"
3. Enable "Google" (add your app's SHA certificates)

### 5. Create Firestore Database
1. Go to Firestore Database
2. Create database in test mode
3. Set up security rules (optional)

## Getting SHA Certificate for Google Sign-In

### Windows:
```bash
cd android
.\gradlew signingReport
```

### macOS/Linux:
```bash
cd android
./gradlew signingReport
```

Copy the SHA1 fingerprint and add it to Firebase project settings.

## Troubleshooting Common Issues

### 1. Flutter Command Not Found
- Ensure Flutter is properly added to PATH
- Restart terminal/command prompt
- Run `where flutter` (Windows) or `which flutter` (macOS/Linux)

### 2. Android License Issues
```bash
flutter doctor --android-licenses
```
Accept all licenses.

### 3. Gradle Issues
```bash
cd android
.\gradlew clean
cd ..
flutter clean
flutter pub get
```

### 4. iOS Issues (macOS only)
```bash
cd ios
pod install
cd ..
```

### 5. Build Runner Issues
```bash
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
```

## OpenAI API Setup

1. **Get API Key**
   - Go to [OpenAI Platform](https://platform.openai.com)
   - Create account and get API key
   - Copy the key (starts with "sk-")

2. **Configure in App**
   - Run the app
   - Go to Settings
   - Tap "OpenAI API Key"
   - Enter your API key
   - AI Assistant will be available

## Running the App

### Development Mode
```bash
flutter run
```

### Debug Mode
```bash
flutter run --debug
```

### Release Mode
```bash
flutter run --release
```

### Build APK
```bash
flutter build apk --release
```

### Build for iOS
```bash
flutter build ios --release
```

## App Features After Setup

Once properly set up, you'll have access to:

✅ **Authentication** - Email/Password and Google Sign-In
✅ **Multi-Wallet Management** - Cash, Bank, Credit, etc.
✅ **Smart Transaction Entry** - Numpad UI with categories
✅ **Beautiful Analytics** - Charts and spending insights
✅ **AI Financial Assistant** - ChatGPT-powered advice
✅ **Cloud Sync** - Firebase backup and sync
✅ **Offline Support** - Works without internet
✅ **Dark/Light Themes** - Material Design 3

## Support

If you encounter issues:
1. Run `flutter doctor` and fix any issues
2. Check the troubleshooting section above
3. Ensure all dependencies are properly installed
4. Verify Firebase configuration is correct

The app is production-ready and includes all the features specified in your requirements! 🚀


