# FlowDesk Setup Guide

## Quick Start (Offline Mode)

FlowDesk works completely offline out of the box! Just run:

```bash
flutter pub get
flutter run
```

The app will start in offline mode with full functionality for:
- ✅ Task management
- 📝 Note taking (with encryption)
- 📅 Calendar events
- 🔍 Search and filtering

## Cloud Sync Setup (Optional)

To enable cross-device sync and cloud backup:

### 1. Firebase Project Setup
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Enable **Authentication** and **Firestore Database**

### 2. Platform Configuration

#### Android
1. Add Android app to Firebase project
2. Download `google-services.json`
3. Place in `android/app/` directory

#### iOS
1. Add iOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/` directory
4. Add to Xcode project

#### Web
1. Add Web app to Firebase project
2. Copy Firebase config
3. Create `web/firebase-config.js` with config

### 3. Authentication Setup
1. In Firebase Console → Authentication → Sign-in method
2. Enable **Email/Password**
3. Enable **Google** (optional)
4. Add your domain to authorized domains

### 4. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## First Run

1. **Launch the app**
2. **Choose mode**:
   - **Sign In/Sign Up**: For cloud sync
   - **Guest Mode**: Offline only
3. **Set encryption passphrase** (recommended)
4. **Start being productive!**

## Features Overview

### 🏠 Home Screen
- Quick overview of today's tasks
- Recent notes
- Upcoming calendar events
- Quick add button for tasks/notes

### ✅ Tasks
- Create with due dates and color tags
- Mark complete/incomplete
- Filter by today, week, all, completed
- Search functionality

### 📅 Calendar
- Monthly/weekly views
- Create events
- Link tasks to calendar
- View tasks due on specific dates

### 📝 Notes
- Markdown editor with live preview
- AES-256 encryption
- Tag-based organization
- Full-text search

### ⚙️ Settings
- Account management
- Encryption passphrase
- Sync preferences
- Data export options

## Troubleshooting

### App won't start
- Run `flutter clean && flutter pub get`
- Check Flutter version: `flutter --version`
- Ensure minimum Flutter 3.8.1

### Sync not working
- Check internet connection
- Verify Firebase configuration
- Check Firestore security rules
- Try manual sync in settings

### Notes not decrypting
- Verify passphrase is correct
- Check if encryption is enabled
- Try setting passphrase again

### Build issues
- Update NDK version in `android/app/build.gradle.kts`
- Run `flutter doctor` to check setup
- Clear build cache: `flutter clean`

## Development

### Run in development
```bash
flutter run
```

### Build for production
```bash
# Android
flutter build apk --release

# iOS
flutter build ipa --release

# Web
flutter build web --release
```

### Testing
```bash
flutter test
flutter analyze
```

## Support

Need help? Check:
1. This setup guide
2. `firebase_setup.md` for detailed Firebase instructions
3. GitHub Issues for known problems
4. Flutter documentation for general Flutter issues

Happy productivity! 🚀