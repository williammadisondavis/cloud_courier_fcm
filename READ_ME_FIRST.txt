Cloud Courier - Activity 14

1) Use the Flutter app you already created and configured with flutterfire.
2) From the project root, install dependencies:
   flutter pub add 'firebase_core:^4.14.0'
   flutter pub add 'firebase_messaging:^16.7.1'
3) Unzip these files into the ROOT of your existing Flutter project.
   This replaces only lib/main.dart, adds lib/fcm_service.dart and images.
   KEEP your existing lib/firebase_options.dart.
4) Add these asset declarations under the existing flutter: heading of pubspec.yaml:

flutter:
  uses-material-design: true
  assets:
    - assets/images/default.png
    - assets/images/promo.png

5) Run:
   flutter pub get
   flutter analyze
   flutter run

Take a setup screenshot only AFTER the running app displays 'FCM ready'.
Do NOT publish or share your device's FCM registration token.
