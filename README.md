# BEACON - Emergency Network Communication App

BEACON is an offline P2P communication and resource sharing application designed to empower communities during emergencies when traditional networks (Cellular, Wi-Fi) fail. It utilizes nearby connections (Bluetooth, Wi-Fi Direct) to create a local mesh network for coordinating relief efforts.

## About the Project

BEACON allows users to discover nearby devices, share text messages, and coordinate essential resources like food, water, and medical supplies completely offline. The app features a high-contrast, accessible UI with voice command support.

### Key Features
*   **Offline Networking**: Peer-to-peer communication using `nearby_connections`.
*   **Resource Sharing**: Real-time broadcasting and requesting of resources.
*   **Voice Control**: integrated Speech-to-Text and Text-to-Speech for hands-free operation.
*   **Emergency Alerts**: Broadcast urgent notifications to the local network.
*   **MVVM Architecture**: Built for reliability and maintainability.

### User Interface

| Dashboard | Resource Sharing | Chat Interface |
|:---:|:---:|:---:|
| ![Dashboard UI Placeholder](images\dashboard.jpeg) | ![Resource Map Placeholder](images\resource.jpeg) | ![Chat UI Placeholder](images\chatpage.jpeg) |



## Setup Details

Follow these instructions to set up the project locally.

### Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (Version 3.9.2 or higher)
*   Dart SDK (Version 3.0.0 or higher)
*   Android Studio / VS Code with Flutter extensions
*   Physical Android/iOS device (Recommended for P2P features)

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/beacon-emergency-network.git
    cd broadcast-emergency-alerts-community-offline-network
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    Connect your device and run:
    ```bash
    flutter run
    ```

### Permissions
The app requires the following permissions to function correctly:
*   **Microphone**: For voice commands and speech recognition.
*   **Location**: Required for Bluetooth Low Energy (BLE) scanning and nearby device discovery.
*   **Nearby Devices**: For establishing P2P connections.
*   **Notifications**: To receive alerts and updates.

Type `flutter run` on a connected device to start exploring the offline network features!
