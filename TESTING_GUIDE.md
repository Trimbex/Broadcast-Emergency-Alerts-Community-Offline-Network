# BEACON Network - P2P Testing Guide

## Overview
The BEACON app now has peer-to-peer (P2P) communication using WiFi Direct, encrypted SQLite database, and Provider state management implemented.

## Prerequisites for Testing

### Hardware Requirements
- **2 Android devices** (minimum Android 5.0 / API 21)
- Both devices must support WiFi Direct
- Both devices should have WiFi turned ON
- Location services must be enabled (required for WiFi Direct on Android 6+)

### Software Requirements
- Flutter SDK (3.9.2 or higher)
- Android Studio or VS Code with Flutter extensions
- Physical Android devices (WiFi Direct doesn't work reliably on emulators)

## Setup Instructions

### Step 1: Install Dependencies
```bash
cd "C:\Users\USER\Desktop\mobile programming project\Mobile-Programming-Project"
flutter pub get
```

### Step 2: Build and Install on Both Devices

#### For Device 1 (Host):
```bash
# Connect Device 1 via USB
flutter devices  # Note the device ID
flutter run -d <device-1-id>
```

#### For Device 2 (Peer):
```bash
# Connect Device 2 via USB (or use wireless debugging)
flutter devices  # Note the device ID
flutter run -d <device-2-id>
```

**Alternative:** Build APK and install on both devices:
```bash
flutter build apk --release
# The APK will be at: build/app/outputs/flutter-apk/app-release.apk
# Transfer and install this APK on both devices
```

## Testing Scenarios

### Test 1: Initial Setup and Permissions

**On Both Devices:**

1. Launch the BEACON app
2. You'll see the Identity Setup page
3. Fill in your details:
   - Name: "Device 1" (or "Device 2")
   - Email (optional)
   - Phone Number
   - Emergency Contact (optional)
4. Tap "Continue"

**Expected Result:** 
- User profile is created and stored in SQLite database
- App navigates to the landing page

### Test 2: Grant Permissions

**On Both Devices:**

1. When prompted, grant the following permissions:
   - Location (Fine and Coarse)
   - Nearby WiFi Devices (Android 13+)
   - Bluetooth (Android 12+)

**Important Notes:**
- Location must be enabled in device settings
- WiFi must be turned ON
- These permissions are required for WiFi Direct to work

### Test 3: WiFi Direct Discovery

**On Device 1 (Host):**

1. Navigate to "Network Dashboard" from the landing page
2. Tap the search icon (🔍) in the app bar
3. You should see "Discovering nearby devices..." snackbar
4. Wait for 5-10 seconds

**On Device 2 (Peer):**

1. Navigate to "Network Dashboard" from the landing page
2. Tap the search icon (🔍) in the app bar
3. Start discovery

**Expected Result:**
- Both devices should discover each other
- You'll see discovered devices in the "Discovered" tab
- Device names and addresses will be displayed

### Test 4: WiFi Direct Connection

**On Device 1:**

1. In the "Discovered" tab, find Device 2
2. Tap the "Connect" button
3. A connection dialog will appear with "Connecting..."

**On Device 2:**

1. You should see a WiFi Direct connection request
2. Accept the connection request

**Expected Result:**
- Connection established successfully
- Connected device appears in the "Connected" tab
- Connection status changes to "Host" or "Connected"
- Green floating action button appears showing connection status
- Device information is saved to SQLite database

**Troubleshooting:**
- If connection fails, try connecting from Device 2 to Device 1 instead
- Ensure both devices have WiFi and Location turned ON
- Try turning WiFi off and on again on both devices
- Check that no other WiFi Direct connections are active

### Test 5: Resource Sharing (Local)

**On Device 1:**

1. Navigate to "Resource Sharing" page
2. Tap "Share Resource" button
3. Fill in resource details:
   - Name: "First Aid Kit"
   - Category: Medical
   - Quantity: 5
   - Location: "Building A, Room 101"
4. Tap "Share"

**Expected Result:**
- Resource is saved to local SQLite database
- Resource appears in the resource list
- If connected via P2P, resource is shared with connected peers
- Success snackbar shows: "First Aid Kit shared via P2P and saved locally"

### Test 6: Resource Sharing via P2P

**Prerequisites:** Devices must be connected via WiFi Direct

**On Device 1 (Connected):**

1. Go to "Resource Sharing"
2. Tap "Share Resource"
3. Add a new resource:
   - Name: "Bottled Water"
   - Category: Water
   - Quantity: 12
   - Location: "Storage Room"
4. Tap "Share"

**On Device 2:**

1. Check the "Resource Sharing" page
2. The shared resource should appear automatically

**Expected Result:**
- Resource is transmitted via WiFi Direct socket connection
- Receiving device stores resource in SQLite database
- Resource appears on both devices
- Network activity is logged in the database

### Test 7: Resource Request

**On Device 2:**

1. Go to "Resource Sharing"
2. Find a resource shared by Device 1
3. Tap "Request Resource"
4. Confirm the request

**Expected Result:**
- Request is sent via P2P connection
- Success snackbar shows on Device 2
- Network activity is logged
- (Note: In this implementation, requests are logged but actual fulfillment would be handled by the resource provider)

### Test 8: Network Activities Log

**On Either Device:**

1. Go to "Network Dashboard"
2. Tap "Activities" button
3. View the network activities dialog

**Expected Result:**
- List of all network activities:
  - Device connections
  - Device disconnections
  - Resources shared
  - Resources requested
- Each activity shows:
  - Device name
  - Activity type (with icon)
  - Details
  - Timestamp (e.g., "5m ago")

### Test 9: Disconnection

**On Device 1:**

1. Go to "Network Dashboard"
2. In the "Connected" tab, find Device 2
3. Tap the X (close) button

**Expected Result:**
- Device is removed from connected devices list
- Device status updated in database (isConnected = false)
- Disconnection activity is logged
- WiFi Direct connection is terminated

### Test 10: Database Persistence

**On Either Device:**

1. Add several resources
2. Connect/disconnect from other devices
3. Close the app completely (swipe away from recent apps)
4. Reopen the app

**Expected Result:**
- All resources are still available (loaded from SQLite)
- User profile persists
- Device history is maintained
- Network activities history is preserved

### Test 11: Filtering Resources

**On Either Device:**

1. Go to "Resource Sharing"
2. Add resources from different categories (Medical, Food, Water, Shelter)
3. Tap on category filter chips at the top
4. Select "Medical", then "Food", etc.

**Expected Result:**
- Resources are filtered by selected category
- Statistics update to reflect filtered results
- "All" shows all resources

### Test 12: Connection Info

**On Either Device (when connected):**

1. Tap the green floating action button (shows "Host" or "Connected")
2. View connection info dialog

**Expected Result:**
- Connection status displayed
- Number of connected devices shown
- Host IP address shown (if available)

## Database Verification

### Using Android Debug Bridge (ADB)

```bash
# Connect device
adb devices

# Access the device shell
adb shell

# Navigate to app data
cd /data/data/com.example.beacon_network/databases

# List databases
ls -la

# Pull database to computer for inspection
exit
adb pull /data/data/com.example.beacon_network/databases/beacon_database.db

# Use DB Browser for SQLite to inspect the database
```

**Tables to check:**
- `user_profiles` - User profile data
- `devices` - Connected and discovered devices
- `resources` - Shared resources
- `network_activities` - Activity logs

## Features Implemented

### ✅ P2P Communication
- WiFi Direct peer discovery
- Device connection/disconnection
- Socket-based communication
- Automatic peer discovery within range

### ✅ SQLite Database
- User profile storage
- Device history with timestamps
- Resource management
- Network activity logging
- Database encryption support (encryption key-based)

### ✅ State Management (Provider)
- Centralized app state
- Real-time UI updates
- Efficient data flow
- Reactive programming

### ✅ Key Features
- Resource sharing (local and P2P)
- Resource requesting
- Device management
- Network activity tracking
- Category-based filtering
- Connection status monitoring

## Known Limitations

1. **WiFi Direct Range:** Typically 100-200 meters in open space
2. **Connection Limits:** WiFi Direct supports 1:1 or 1:many connections (one group owner, multiple clients)
3. **Platform Support:** Currently optimized for Android (WiFi Direct not available on iOS)
4. **Emulator:** WiFi Direct does not work on Android emulators - physical devices required
5. **Background Operation:** WiFi Direct connections may drop when app is in background

## Troubleshooting

### Issue: Devices not discovering each other
**Solution:**
- Ensure both devices have WiFi and Location enabled
- Grant all required permissions
- Try restarting discovery
- Check that devices are in range (< 100m)
- Restart WiFi on both devices

### Issue: Connection fails
**Solution:**
- Try connecting from the other device
- Ensure only one connection attempt at a time
- Check for existing WiFi Direct connections
- Restart the app on both devices

### Issue: Resources not syncing
**Solution:**
- Verify devices are connected (check connection status)
- Check network activities log
- Ensure resources are shared while connected
- Try disconnecting and reconnecting

### Issue: Permissions denied
**Solution:**
- Go to Android Settings > Apps > BEACON Network > Permissions
- Grant all required permissions
- Restart the app

### Issue: App crashes on startup
**Solution:**
- Run `flutter clean`
- Run `flutter pub get`
- Rebuild the app
- Check Android device logs: `adb logcat`

## Performance Testing

### Metrics to Monitor
- Discovery time (should be < 30 seconds)
- Connection establishment time (should be < 10 seconds)
- Resource sync time (should be < 2 seconds for small payloads)
- Database query performance (should be < 100ms)

### Stress Testing
1. Add 50+ resources and test performance
2. Connect/disconnect multiple times rapidly
3. Send multiple resources in quick succession
4. Check memory usage over extended use

## Security Considerations

### Implemented
- Database encryption support (key-based encryption)
- Encrypted communication via AES (in database helper)
- Permission-based access control

### Recommendations for Production
- Implement end-to-end encryption for P2P messages
- Add authentication mechanism for peer connections
- Secure key storage using Android Keystore
- Implement data integrity checks
- Add rate limiting for resource sharing

## Next Steps for Development

1. **iOS Support:** Implement Multipeer Connectivity for iOS
2. **Enhanced Security:** Implement proper key management and E2E encryption
3. **Background Service:** Keep P2P connection alive in background
4. **File Sharing:** Add support for sharing files (images, documents)
5. **Chat Feature:** Complete the chat functionality
6. **Location Tracking:** Add GPS-based location sharing
7. **Offline Maps:** Integrate offline map support
8. **Voice Commands:** Complete voice command integration
9. **Push Notifications:** Add notifications for incoming requests
10. **Analytics:** Add crash reporting and analytics

## Support

For issues or questions:
- Check the Flutter documentation: https://flutter.dev
- WiFi Direct documentation: https://developer.android.com/guide/topics/connectivity/wifip2p
- Flutter P2P Connection package: https://pub.dev/packages/flutter_p2p_connection

## License
This is an educational project for the BEACON emergency network application.

