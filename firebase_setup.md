# Firebase Setup for FlowDesk

## Prerequisites
1. Create a Firebase project at https://console.firebase.google.com/
2. Enable Authentication and Firestore Database

## Android Setup
1. Add your Android app to Firebase project
2. Download `google-services.json`
3. Place it in `android/app/` directory
4. The build.gradle files are already configured

## iOS Setup
1. Add your iOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Place it in `ios/Runner/` directory
4. Add it to Xcode project

## Web Setup
1. Add your Web app to Firebase project
2. Copy the Firebase config
3. Create `web/firebase-config.js` with your config

## Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Authentication Setup
1. Enable Email/Password authentication
2. Enable Google Sign-In
3. Add your domain to authorized domains

## Google Drive API Setup (Optional)
1. Enable Google Drive API in Google Cloud Console
2. Create OAuth 2.0 credentials
3. Add authorized redirect URIs
4. Update the app with your client IDs