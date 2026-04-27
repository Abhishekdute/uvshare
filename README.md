# 🚀 UVShare - Ultra-Fast File Sharing

**UVShare** is a modern, high-performance file-sharing application built with Flutter. It allows users to transfer files across devices on the same network with incredible speed using local WiFi, bypassing the need for slow internet or cables.

![Banner](https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey?style=for-the-badge)

## ✨ Features

- **⚡ Ultra-Fast Transfer:** Leverages local network speeds for maximum throughput.
- **📱 Cross-Platform:** Works seamlessly across Android, iOS, and other supported platforms.
- **🔍 Auto-Discovery:** Automatically find devices on your network using mDNS.
- **📸 QR Connection:** Connect instantly by scanning a QR code.
- **📂 Multi-File Support:** Send photos, videos, documents, and even APKs.
- **🔒 Secure:** Local transfers mean your data never leaves your network.
- **🎨 Modern UI:** Clean, responsive design with smooth animations and glassmorphism elements.

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev)
- **State Management:** [Provider](https://pub.dev/packages/provider)
- **Discovery:** [multicast_dns](https://pub.dev/packages/multicast_dns), [network_info_plus](https://pub.dev/packages/network_info_plus)
- **Scanning:** [mobile_scanner](https://pub.dev/packages/mobile_scanner)
- **UI Components:** [flutter_staggered_animations](https://pub.dev/packages/flutter_staggered_animations), [qr_flutter](https://pub.dev/packages/qr_flutter)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Latest stable version recommended)
- Android Studio / VS Code
- A physical device or emulator for testing

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/uvshare.git
   cd uvshare
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

## 📱 How to Use

1. **To Send:**
   - Tap on "Send Files".
   - Select the receiver from the discovered devices or scan their QR code.
   - Choose the files you want to share.
   - Tap "Start Transfer".

2. **To Receive:**
   - Tap on "Receive Files".
   - Keep the screen open and let the sender find you, or show your QR code to the sender.

## 🛠️ Configuration (Android)

Make sure you have the following permissions in your `AndroidManifest.xml`:
- `INTERNET`
- `ACCESS_WIFI_STATE`
- `CHANGE_WIFI_MULTICAST_STATE`
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` (for file picking)

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests to make UVShare even better.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
Made with ❤️ by [Abhishek]
