# Fix: Could NOT find JNI (JAVA_INCLUDE_PATH) on Windows

This error happens when building Flutter for **Windows** and a plugin (e.g. `jni` used by `local_auth` or others) needs the Java JNI headers. CMake cannot find them.

## Fix

### 1. Install a full JDK (not just JRE)

Use a JDK that includes the `include` folder (JNI headers):

- **Eclipse Temurin (Adoptium)** – recommended: https://adoptium.net/
  - Download **JDK 17** (or 21) for Windows (e.g. `.msi`).
  - During install, enable **“Set JAVA_HOME variable”** if offered.
- Or use the JDK that comes with **Android Studio**:  
  `C:\Program Files\Android\Android Studio\jbr`  
  (Only use this if it contains an `include` folder; some bundles do not.)

### 2. Set JAVA_HOME

Point `JAVA_HOME` to the **root of the JDK** (the folder that contains `bin`, `include`, `lib`):

**PowerShell (current session):**
```powershell
$env:JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.13.11-hotspot"   # adjust to your path
```

**System environment variable (permanent):**
1. Win + R → `sysdm.cpl` → Enter.
2. **Advanced** → **Environment Variables**.
3. Under **System variables** → **New** (or edit existing):
   - Variable: `JAVA_HOME`
   - Value: `C:\Program Files\Eclipse Adoptium\jdk-17.0.13.11-hotspot` (your JDK path).
4. OK and restart the terminal/IDE.

### 3. Optional: set JNI include paths

If the error persists, set the include paths explicitly (same place as JAVA_HOME):

**PowerShell:**
```powershell
$j = $env:JAVA_HOME
$env:JAVA_INCLUDE_PATH = "$j\include"
$env:JAVA_INCLUDE_PATH2 = "$j\include\win32"
```

### 4. Clean and rebuild

```powershell
cd c:\Users\abrek_otvjrzk\StudioProjects\Finsor
flutter clean
flutter pub get
flutter build windows
```

If you only need **Android**, build that instead; it does not use this Windows/JNI path:

```powershell
flutter build apk
# or
flutter run
```

(For `flutter run`, choose an Android device/emulator when prompted.)
