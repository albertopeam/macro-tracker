# Macro Tracker — Setup Instructions

## 1. Install Flutter

https://docs.flutter.dev/get-started/install/macos

Verify: `flutter doctor`

## 2. Scaffold the project

```bash
cd /Users/alberto/Documents/claude/test
flutter create --org com.yourname macro_tracker_tmp
```

Then copy these generated platform dirs into the macro_tracker folder:
```bash
cp -r macro_tracker_tmp/android macro_tracker/android
cp -r macro_tracker_tmp/ios     macro_tracker/ios
rm -rf macro_tracker_tmp
```

## 3. Android permissions (required for microphone)

Edit `macro_tracker/android/app/src/main/AndroidManifest.xml`.

Add inside `<manifest>`, before `<application>`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>

<queries>
    <intent>
        <action android:name="android.speech.RecognitionService" />
    </intent>
</queries>
```

Also set minSdkVersion in `android/app/build.gradle`:
```
minSdkVersion 21
```

## 4. iOS permissions (if building for iOS)

Edit `ios/Runner/Info.plist`. Add:
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>Used to log meals by voice.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Used to record meal descriptions.</string>
```

## 5. Install dependencies & run

```bash
cd macro_tracker
flutter pub get
flutter run
```

## Food database

The app seeds `assets/foods/foods.csv` on first launch into a local SQLite
database. ~100 common foods are included. You can extend the CSV with more
entries — just clear app data or increment the `db_seeded_v1` SharedPreferences
key to force a re-seed.

## Color legend (Calendar)

| Color  | Meaning                          |
|--------|----------------------------------|
| Green  | ≥ 90% of calorie goal            |
| Yellow | 50–89% of goal                   |
| Red    | < 50% of goal                    |
| Orange | > 115% of goal (over target)     |
| Grey   | No entries logged                |
