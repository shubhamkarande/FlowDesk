# FlowDesk - Create, Write, Plan. No Wi-Fi Needed.

FlowDesk is a comprehensive offline-first productivity suite built with Flutter. It allows users to manage to-dos, schedule tasks on a calendar, and write encrypted notes — all offline — with optional cloud sync to Firebase and Google Drive export.

## ✨ Features

### 🔄 Offline-First Architecture
- **Complete offline functionality** - All features work without internet
- **SQLite local storage** - Fast, reliable local data storage
- **Background sync** - Automatic sync when connection is restored
- **Conflict resolution** - Smart handling of data conflicts

### ✅ Task Management
- Create, edit, and organize tasks
- Set due dates and color-coded tags
- Mark tasks as complete
- Filter by today, week, or completion status
- Search through tasks

### 📅 Integrated Calendar
- Monthly and weekly calendar views
- Drag and drop events (planned feature)
- Link tasks to calendar events
- View tasks and events by date
- Create events from tasks

### 📝 Encrypted Notes
- Markdown-style note editor with live preview
- AES-256 encryption with user passphrase
- Tag-based organization
- Full-text search
- Rich text formatting support

### 🔐 Security & Privacy
- **End-to-end encryption** for notes
- **User-controlled passphrase** - only you can decrypt your notes
- **Secure storage** using Flutter Secure Storage
- **Optional cloud sync** - works completely offline if preferred

### ☁️ Cloud Sync & Backup
- **Firebase Firestore** sync for cross-device access
- **Firebase Authentication** with email/password and Google Sign-In
- **Guest mode** for offline-only usage
- **Google Drive export** (planned feature)
- **Last-write-wins** conflict resolution

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project (for cloud features)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/flowdesk.git
   cd flowdesk
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup** (Optional - for cloud sync)
   - Follow the instructions in `firebase_setup.md`
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Run the app**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter (Cross-platform: iOS, Android, Web, Desktop)
- **Local Database**: SQLite via `sqflite`
- **Cloud Backend**: Firebase Firestore + Firebase Auth
- **Encryption**: AES-256 via `encrypt` package
- **State Management**: Provider pattern
- **Calendar**: `table_calendar` package
- **Markdown**: `flutter_markdown` package

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── todo.dart
│   ├── note.dart
│   └── calendar_event.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   ├── todo_provider.dart
│   ├── note_provider.dart
│   └── calendar_provider.dart
├── services/                 # Business logic
│   ├── database_service.dart
│   ├── auth_service.dart
│   ├── sync_service.dart
│   └── encryption_service.dart
└── screens/                  # UI screens
    ├── splash_screen.dart
    ├── auth_screen.dart
    ├── home_screen.dart
    ├── todo_screen.dart
    ├── calendar_screen.dart
    ├── notes_screen.dart
    ├── note_editor_screen.dart
    ├── settings_screen.dart
    └── passphrase_screen.dart
```

### Data Flow
1. **Offline-First**: All CRUD operations use SQLite first
2. **Encryption**: Notes are encrypted before saving locally or syncing
3. **Background Sync**: When online, data syncs with Firebase automatically
4. **Conflict Resolution**: Local changes take precedence (last-write-wins)

## 🔧 Configuration

### Environment Setup
The app works out of the box in offline mode. For cloud features:

1. **Firebase Configuration**
   - Create a Firebase project
   - Enable Firestore and Authentication
   - Add platform-specific config files

2. **Google Drive API** (Optional)
   - Enable Google Drive API in Google Cloud Console
   - Configure OAuth 2.0 credentials

### Security Configuration
- **Encryption Passphrase**: Set during first run or in settings
- **Firebase Security Rules**: Configured to allow user-specific access only
- **Local Storage**: Uses Flutter Secure Storage for sensitive data

## 📱 Usage

### Getting Started
1. **First Launch**: Choose between signing in or using guest mode
2. **Set Passphrase**: Configure encryption for your notes (optional but recommended)
3. **Start Creating**: Add tasks, notes, and calendar events

### Key Features
- **Quick Add**: Use the floating action button on home screen
- **Search**: Find tasks and notes quickly with built-in search
- **Sync Status**: Visual indicators show sync status for each item
- **Offline Mode**: Full functionality without internet connection

### Tips
- **Backup Important Data**: Use cloud sync or export features
- **Remember Your Passphrase**: Cannot be recovered if forgotten
- **Regular Sync**: Connect to internet periodically to sync data

## 🛠️ Development

### Building for Production

**Android APK**
```bash
flutter build apk --release
```

**iOS IPA**
```bash
flutter build ipa --release
```

**Web PWA**
```bash
flutter build web --release
```

### Testing
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All the open-source package contributors

## 📞 Support

If you encounter any issues or have questions:
1. Check the [Issues](https://github.com/yourusername/flowdesk/issues) page
2. Create a new issue with detailed information
3. Join our community discussions

---

**FlowDesk** - Your offline-first productivity companion. Create, Write, Plan. No Wi-Fi Needed. 🚀
