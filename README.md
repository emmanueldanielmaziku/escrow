# Escrow App

A modern and secure mobile application for handling contract escrow agreements between two parties.

## Features

### Core Functionality

- **Secure Contract Creation**: Create and manage escrow contracts with ease
- **Payment Management**: Fund contracts and handle secure payments
- **Real-time Updates**: Get instant notifications about contract status changes
- **User Authentication**: Secure login and registration system
- **Profile Management**: Update user information and preferences

### Notification Settings

The app includes a comprehensive notification management system that allows users to:

- **Enable/Disable Push Notifications**: Toggle all notifications on or off
- **Notification Types**:
  - Contract Updates: New contracts, status changes, and updates
  - Payment Notifications: Payment confirmations and balance updates
  - System Notifications: App updates and maintenance notices
- **Sound & Vibration Controls**: Customize notification sounds and vibration
- **Reset to Defaults**: Easily restore default notification settings

### How to Access Notification Settings

1. Open the app and navigate to your profile
2. Tap on "Notifications" in the Settings section
3. Customize your notification preferences
4. Changes are automatically saved and applied

## Technical Stack

- **Framework**: Flutter
- **Backend**: Firebase (Firestore, Authentication, Cloud Messaging)
- **State Management**: Provider
- **Notifications**: Firebase Cloud Messaging + Local Notifications
- **UI**: Material Design with custom theming

## Getting Started

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Configure Firebase (add your `google-services.json` and `service-account-key.json`)
4. Run the app: `flutter run`

## Project Structure

```
lib/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Business logic and API calls
├── utils/           # Utilities and constants
└── widgets/         # Reusable UI components
```

## Contributing

This project is a starting point for a Flutter application. Feel free to contribute by submitting issues or pull requests.
