# MVVM Architecture

This project follows the **Model-View-ViewModel (MVVM)** architectural pattern for better separation of concerns and maintainability.

## Architecture Overview

```
lib/
├── models/          # Data models (M in MVVM)
├── viewmodels/      # ViewModels - UI state & logic (VM in MVVM)
├── screens/         # Views - UI presentation (V in MVVM)
├── widgets/         # Reusable UI components
└── services/        # Business logic & data services
```

## Components

### 📊 **Models** (`lib/models/`)
- Pure data classes
- Represent domain entities
- Examples: `DeviceModel`, `MessageModel`, `ResourceModel`

### 🎨 **Views** (`lib/screens/` & `lib/widgets/`)
- **Screens**: Top-level UI pages
- **Widgets**: Reusable UI components
- **Responsibility**: Display data and forward user interactions to ViewModels
- **Examples**: `ChatPage`, `NetworkDashboard`, `ResourceSharingPage`

### 🧠 **ViewModels** (`lib/viewmodels/`)
- Manage UI state for specific screens
- Handle user interactions
- Communicate with Services
- Notify Views of state changes via `ChangeNotifier`
- **Examples**: `ChatViewModel`, `NetworkDashboardViewModel`, `ResourceSharingViewModel`

### ⚙️ **Services** (`lib/services/`)
- Business logic and data operations
- Shared across multiple ViewModels
- Handle platform-specific APIs
- **Examples**: `P2PService`, `DatabaseService`, `NotificationService`

## MVVM Flow

```
User Action → View → ViewModel → Service → Model
                ↑         ↓
                └─────────┘
             (notifyListeners)
```

1. **User interacts** with the View (e.g., taps send button)
2. **View calls** ViewModel method
3. **ViewModel** processes logic and calls Services
4. **Services** perform operations (DB, Network, etc.)
5. **ViewModel** updates state and calls `notifyListeners()`
6. **View** rebuilds automatically via `Consumer` or `Provider`

## Key Benefits

✅ **Separation of Concerns**: UI logic separated from business logic  
✅ **Testability**: ViewModels can be unit tested without UI  
✅ **Reusability**: ViewModels can be shared across multiple Views  
✅ **Maintainability**: Cleaner code structure, easier to modify  
✅ **State Management**: Centralized state in ViewModels

## Usage Example

### ChatPage Implementation

```dart
// 1. Screen creates ViewModel
class _ChatPageState extends State<ChatPage> {
  ChatViewModel? _viewModel;

  @override
  void initState() {
    super.initState();
    final p2pService = Provider.of<P2PService>(context, listen: false);
    _viewModel = ChatViewModel(p2pService: p2pService);
    _viewModel!.initialize(device);
  }

  // 2. Provide ViewModel to widget tree
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ChatViewModel>.value(
      value: _viewModel!,
      child: Consumer<ChatViewModel>(
        builder: (context, viewModel, child) {
          // 3. UI reacts to ViewModel state
          return ListView.builder(
            itemCount: viewModel.messages.length,
            itemBuilder: (context, index) {
              return MessageBubble(message: viewModel.messages[index]);
            },
          );
        },
      ),
    );
  }

  // 4. User actions trigger ViewModel methods
  void _sendMessage() {
    _viewModel!.sendMessage(messageText);
  }
}
```

## ViewModels Overview

### `BaseViewModel`
- Abstract base class for all ViewModels
- Provides common functionality:
  - `isLoading` - Loading state
  - `errorMessage` - Error handling
  - `safeNotifyListeners()` - Safe state updates

### `ChatViewModel`
- Manages chat messages for a device
- Handles sending/receiving messages
- Loads message history from database

### `NetworkDashboardViewModel`
- Controls P2P network state
- Manages device connections
- Handles network initialization and refresh

### `ResourceSharingViewModel`
- Manages resource listing and filtering
- Handles resource requests
- Coordinates resource sharing between devices

### `ProfileViewModel`
- Manages user profile data
- Handles emergency contacts
- Validates and saves user information

## Best Practices

1. **ViewModels should NOT**:
   - Import `flutter/material.dart` (except for debugging)
   - Directly manipulate widgets
   - Navigate between screens

2. **Views should NOT**:
   - Contain business logic
   - Directly access Services
   - Manage complex state

3. **Services should**:
   - Be reusable across ViewModels
   - Handle a single responsibility
   - Use `ChangeNotifier` for global state

## Testing

ViewModels are easily testable:

```dart
test('ChatViewModel sends message', () async {
  final mockP2PService = MockP2PService();
  final viewModel = ChatViewModel(p2pService: mockP2PService);
  
  await viewModel.sendMessage('Hello');
  
  expect(viewModel.messages.length, 1);
  expect(viewModel.messages.first.content, 'Hello');
});
```

## Migration Notes

All screens have been refactored to use ViewModels:
- ✅ `ChatPage` → `ChatViewModel`
- ✅ `NetworkDashboard` → `NetworkDashboardViewModel`
- ✅ `ResourceSharingPage` → `ResourceSharingViewModel`
- ✅ `ProfilePage` → `ProfileViewModel`

Services (`P2PService`, `ThemeService`) remain as global state managers provided at the app level in `main.dart`.
