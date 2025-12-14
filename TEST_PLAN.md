# BEACON Emergency Network - Test Plan & Test Cases

## 📋 Overview

This document describes the comprehensive testing strategy for the BEACON Emergency Network application, including all test cases, test types, and execution guidelines.

## 🎯 Testing Strategy

### Test Pyramid

```
    Integration Tests (3)
          /\
         /  \
        /    \
       /      \
      /        \
 Unit Tests (4 ViewModels)
```

### Test Coverage Goals

- **Unit Tests**: 80%+ coverage for ViewModels and business logic
- **Integration Tests**: Critical end-to-end workflows

## 📁 Test Structure

```
test/
├── viewmodels/           # Unit tests for ViewModels
│   ├── chat_viewmodel_test.dart
│   ├── network_dashboard_viewmodel_test.dart
│   ├── profile_viewmodel_test.dart
│   └── resource_sharing_viewmodel_test.dart
└── mocks/
    └── mock_services.dart    # Mock implementations

integration_test/
├── app_initialization_test.dart
├── network_workflow_test.dart
└── resource_sharing_workflow_test.dart
```

---

## 🧪 Unit Tests (4 Test Suites, 50+ Test Cases)

### 1. ChatViewModel Tests (12 test cases)

**File**: `test/viewmodels/chat_viewmodel_test.dart`

| # | Test Case | Description | Expected Result |
|---|-----------|-------------|-----------------|
| 1.1 | Initial state should be empty | Verify ViewModel starts with empty state | messages=[], device=null, isLoading=false |
| 1.2 | Initialize should load messages from database | Load existing messages on init | Messages loaded from DB |
| 1.3 | Send message should add message to list | Send text message | Message sent via P2P, added to list |
| 1.4 | Send empty message should return false | Try sending empty/whitespace message | Returns false, no message sent |
| 1.5 | Send quick message should broadcast emergency | Send SOS quick message | Broadcasts emergency alert |
| 1.6 | isConnected should return true when device connected | Check connection status | Returns true if device in connected list |
| 1.7 | Error during initialization should set error message | Simulate DB error on init | errorMessage set, isLoading=false |
| 1.8 | Messages should be sorted by timestamp | Load unsorted messages | Messages sorted chronologically |
| 1.9 | Duplicate messages should not be added | Receive duplicate message | Only one instance in list |
| 1.10 | Refresh messages should reload from DB | Call refreshMessages() | Messages reloaded from database |
| 1.11 | Send message to disconnected device should fail | Send when device not connected | Error set, returns false |
| 1.12 | Dispose should clean up resources | Call dispose() | Subscriptions cancelled |

### 2. NetworkDashboardViewModel Tests (10 test cases)

**File**: `test/viewmodels/network_dashboard_viewmodel_test.dart`

| # | Test Case | Description | Expected Result |
|---|-----------|-------------|-----------------|
| 2.1 | Initial state should be initializing | Check initial state | networkState=initializing |
| 2.2 | Initialize should start network services | Call initialize() | P2P initialized, advertising, discovering |
| 2.3 | Successful initialization should set state to searching | Init with valid data | networkState=searching |
| 2.4 | Failed initialization should set error state | Simulate init failure | networkState=error, errorMessage set |
| 2.5 | Refresh network should restart discovery | Call refreshNetwork() | Discovery restarted |
| 2.6 | Connected devices should reflect P2P service state | Add devices to P2P service | connectedDevices updated |
| 2.7 | Broadcast emergency should call P2P service | Broadcast emergency message | Message sent via P2P |
| 2.8 | isNetworkActive should be true when services active | Check after init | Returns true |
| 2.9 | Mode should be set correctly | Initialize with 'host' mode | mode='host' |
| 2.10 | Error during refresh should set error message | Simulate refresh failure | errorMessage set |

### 3. ResourceSharingViewModel Tests (10 test cases)

**File**: `test/viewmodels/resource_sharing_viewmodel_test.dart`

| # | Test Case | Description | Expected Result |
|---|-----------|-------------|-----------------|
| 3.1 | Initial state should have All category selected | Check initial state | selectedCategory='All' |
| 3.2 | Set category should update selected category | Call setCategory('Medical') | selectedCategory='Medical' |
| 3.3 | Filtered resources should show all when category is All | Add resources, set All | All resources shown |
| 3.4 | Filtered resources should show only selected category | Set Medical category | Only Medical resources shown |
| 3.5 | Add resource should broadcast to network | Add new resource | Resource broadcasted |
| 3.6 | Available count should count non-unavailable resources | Add available and unavailable | Correct count returned |
| 3.7 | Request resource should call P2P service | Request a resource | Request sent with correct params |
| 3.8 | Duplicate resources should be filtered | Add same resource twice | Only one instance shown |
| 3.9 | Shared count should count local resources | Add local and remote resources | Correct shared count |
| 3.10 | Delete resource should remove from list | Delete a resource | Resource removed |

### 4. ProfileViewModel Tests (14 test cases)

**File**: `test/viewmodels/profile_viewmodel_test.dart`

| # | Test Case | Description | Expected Result |
|---|-----------|-------------|-----------------|
| 4.1 | Initial state should be empty | Check initial state | All fields empty |
| 4.2 | Initialize should load profile from database | Call initialize() | Profile data loaded |
| 4.3 | Update field should modify profile data | Update name and phone | Fields updated |
| 4.4 | Save profile with valid data should succeed | Save valid profile | Returns true, no error |
| 4.5 | Save profile with invalid phone should fail | Save with invalid phone | Returns false, error set |
| 4.6 | Validate phone number should reject invalid formats | Test various invalid phones | Validation errors returned |
| 4.7 | Validate phone number should accept valid formats | Test valid phone numbers | No validation errors |
| 4.8 | Add emergency contact with valid data should succeed | Add valid contact | Returns true, contact added |
| 4.9 | Add emergency contact with invalid phone should fail | Add with invalid phone | Returns false, error set |
| 4.10 | Delete emergency contact should remove from list | Delete contact | Contact removed |
| 4.11 | Emergency contacts should be loaded on init | Initialize with contacts in DB | Contacts loaded |
| 4.12 | Save profile without device ID should fail | Save before init | Returns false, error set |
| 4.13 | Reload should refresh profile data | Call reload() | Profile reloaded from DB |
| 4.14 | Error during save should set error message | Simulate DB error | Error message set |

---

## 🎨 Widget Tests (2 Test Suites, 10+ Test Cases)

### 5. ChatPage Widget Tests (5 test cases)

**File**: `test/widgets/chat_page_widget_test.dart`

| # | Test Case | Description | Expected Result |
|---|-----------|-------------|-----------------|
| 5.1 | Should display empty chat state initially | Open chat with no messages | "No messages yet" shown |
| 5.2 | Should display message input bar | Load chat page | TextField and send button visible |
| 5.3 | Should display quick action buttons | Load chat page | SOS, Location, Safe buttons shown |
| 5.4 | Should show device info dialog when info button tapped | Tap info icon | Dialog with device details shown |
| 5.5 | Should display messages in list | Load with messages | Messages displayed in ListView |

### 6. NetworkDashboard Widget Tests (5 test cases)

**File**: `test/widgets/network_dashboard_widget_test.dart`

| # | Test Case | Description | Expected Result |
|---|-----------|-------------|-----------------|
| 6.1 | Should display network status indicator | Load dashboard | Status indicator visible |
| 6.2 | Should display refresh button | Load dashboard | Refresh button in app bar |
| 6.3 | Should display connected devices when available | Add devices to service | Devices displayed in list |
| 6.4 | Should show empty state when no devices | Load with no connections | "Searching" message shown |
| 6.5 | Should display app bar with title | Load dashboard | "Emergency Network" title shown |

---

## 🔄 Integration Tests (3 Test Suites, 10+ Test Cases)

### 7. App Initialization Integration Tests (2 test cases)

**File**: `integration_test/app_initialization_test.dart`

| # | Test Case | Description | Expected Result |
|---|-----------|-------------|-----------------|
| 7.1 | App should launch and show identity setup | Launch app | Identity setup page shown |
| 7.2 | Can navigate from identity setup to network dashboard | Complete setup flow | Navigate to dashboard successfully |

### 8. Network Discovery Workflow Tests (2 test cases)

**File**: `integration_test/network_workflow_test.dart`

| # | Test Case | Description | Expected Result |
|---|-----------|-------------|-----------------|
| 8.1 | Complete network setup workflow | Full setup from start | Network initialized and searching |
| 8.2 | Can refresh network discovery | Tap refresh button | Network discovery restarted |

### 7. Resource Sharing Workflow Tests (3 test cases)

**File**: `integration_test/resource_sharing_workflow_test.dart`

| # | Test Case | Description | Expected Result |
|---|-----------|-------------|------------------|
| 7.1 | Can navigate to resource sharing page | Navigate to resources | Resource page displayed |
| 7.2 | Can filter resources by category | Select category filter | Resources filtered correctly |
| 7.3 | Can open add resource dialog | Tap Share Resource button | Add resource dialog opens |

---

## 🚀 Running Tests

### Prerequisites

```bash
flutter pub get
```

### Run All Unit Tests

```bash
flutter test
```

### Run Specific Test File

```bash
flutter test test/viewmodels/chat_viewmodel_test.dart
```

### Run Widget Tests

```bash
flutter test test/widgets/
```

### Run Integration Tests

```bash
# On Android
flutter test integration_test/app_initialization_test.dart

# On specific device
flutter test integration_test/ -d <device_id>
```

### Run with Coverage

```bash
flutter test --coverage
```

### Generate Coverage Report

```bash
# Install lcov
# Windows: choco install lcov
# Mac: brew install lcov
# Linux: sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
# Windows
start coverage/html/index.html

# Mac
open coverage/html/index.html

# Linux
xdg-open coverage/html/index.html
```

---

## 📊 Test Coverage Summary

| Component | Test Type | Test Files | Test Cases | Priority |
|-----------|-----------|-----------|------------|----------|
| ChatViewModel | Unit | 1 | 12 | High |
| NetworkDashboardViewModel | Unit | 1 | 10 | High |
| ResourceSharingViewModel | Unit | 1 | 10 | High |
| ProfileViewModel | Unit | 1 | 14 | High |
| App Workflows | Integration | 3 | 7 | High |
| **Total** | | **7** | **53** | |

---

## 🎯 Testing Best Practices

### 1. **AAA Pattern** (Arrange-Act-Assert)
```dart
test('Description', () {
  // Arrange - Set up test data
  final viewModel = ChatViewModel(...);
  
  // Act - Execute the action
  await viewModel.sendMessage('Test');
  
  // Assert - Verify the result
  expect(viewModel.messages.length, equals(1));
});
```

### 2. **Descriptive Test Names**
- Use clear, descriptive names
- Start with "should" or describe expected behavior
- Include context and expected result

### 3. **Isolated Tests**
- Each test should be independent
- Use setUp() and tearDown()
- Don't rely on test execution order

### 4. **Mock External Dependencies**
- Use mock services for testing
- Isolate unit under test
- Test behavior, not implementation

### 5. **Test Edge Cases**
- Test null/empty inputs
- Test error conditions
- Test boundary values

---

## 🐛 Continuous Integration

### GitHub Actions Example

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter test integration_test/
```

---

## 📝 Test Maintenance

### When to Update Tests

1. **After adding new features** - Add corresponding tests
2. **When fixing bugs** - Add regression tests
3. **After refactoring** - Ensure tests still pass
4. **When modifying ViewModels** - Update unit tests

### Red-Green-Refactor Cycle

1. **Red**: Write failing test
2. **Green**: Write minimal code to pass
3. **Refactor**: Improve code while keeping tests green

---

## 🎓 Future Test Enhancements

- [ ] Add widget tests (requires refactoring for testability)
- [ ] Add service layer unit tests
- [ ] Add model validation tests
- [ ] Add performance tests
- [ ] Add accessibility tests
- [ ] Increase integration test coverage
- [ ] Add E2E tests for critical paths
- [ ] Add visual regression tests
- [ ] Add load/stress tests

---

## ✅ Test Checklist

Before releasing:

- [ ] All unit tests pass
- [ ] All widget tests pass
- [ ] All integration tests pass
- [ ] Code coverage > 80%
- [ ] No failing tests in CI/CD
- [ ] New features have corresponding tests
- [ ] Bug fixes have regression tests
- [ ] Tests run in < 5 minutes

---

**Last Updated**: December 14, 2025  
**Test Framework**: Flutter Test, Integration Test  
**Total Test Cases**: 53  
**Test Coverage Goal**: 80%+
