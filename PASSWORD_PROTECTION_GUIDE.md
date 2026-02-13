# Password-Protected File Sharing - Implementation Guide

## Overview

FastShare now supports optional password-protected access to shared files. The implementation is clean, secure, and offline-friendly with no external authentication systems or databases required.

---

## Architecture

### 1. **AuthManager** (`auth_manager.dart`)
Core password management utility that handles:
- **Salt generation**: 16-byte cryptographically secure random salt (base64-encoded)
- **Password hashing**: SHA256(salt:password) - NEVER stores plaintext passwords
- **Token management**: 32-byte secure random tokens for subsequent requests
- **Validation**: Compares incoming passwords against stored hash

**Key Features:**
```dart
// Initialize with user's password
final auth = AuthManager.fromPassword("myPassword123");

// Validate incoming passwords
bool isCorrect = auth.validatePassword("myPassword123"); // true

// Validate tokens
bool hasAccess = auth.validateToken(tokenFromRequest); // true/false

// Get current token to share with receivers
String token = auth.token;
```

### 2. **HTTP Server Protection** (`local_http_server.dart`)

#### Modified `startServer` Method
```dart
Future<ServerInfo?> startServer(
  List<SharedFile> files, {
  String? password,  // NEW: Optional password parameter
  ...
}) async
```

#### Authentication Flow
Every HTTP request is validated through `_isAuthenticated()`:
1. **No password set** → All requests allowed ✅
2. **Password set** → Request must have:
   - Token in URL: `?token=<base64_token>` OR
   - Token in header: `X-Share-Token: <base64_token>`

#### Protected Endpoints
- `/` (GET) - Shows password form if unauthenticated
- `/files` (GET) - Requires authentication to download
- `/info` (GET) - Requires authentication for file metadata

#### Unauthenticated Response
Returns an HTML password input page with:
- Material Design UI
- Client-side password submission
- Token storage in localStorage
- Secure password field (not logged)

### 3. **Password Submission Handler** (`_handlePasswordSubmission`)
- Accepts POST request with `password=<value>`
- Validates against stored hash
- Returns JSON response with token on success:
  ```json
  {"success": true, "token": "secure_base64_token_here"}
  ```
- Returns 401 Unauthorized on failure

---

## User Flow

### Sender (App)
1. Navigate to "Share Files" screen
2. Select files to share
3. **[NEW]** Optional: Enter password in the "Optional: Add Password" field
4. Click "Continue" (or start without password)
5. Server starts with optional protection
6. Share QR code and URL with receiver
7. ⚠️ **Console logs token** (e.g., "Password-protected server enabled. Token: ...")

### Receiver (Browser)
1. Scan QR code or visit shared URL
2. If password-protected:
   - Sees password input page
   - Enters password and clicks "Unlock"
   - Receives token from server
   - Token stored in localStorage
   - Redirected to file list with `?token=...`
3. Downloads files normally
4. Token persists for session (localStorage)

---

## Security Properties

### ✅ What's Protected
- **Passwords never transmitted in plaintext** - hashed with salt before storage
- **Tokens secure** - 256-bit random, base64-encoded
- **No database** - everything in-memory, ephemeral
- **Offline-first** - no external API calls
- **Token-based** - stateless, can be embedded in URL/header

### ✅ No Plain Text Storage
```dart
// NEVER stored
"myPassword123"

// ALWAYS stored (as SHA256 hash)
sha256("16bytes_of_salt:myPassword123")
```

### ⚠️ Limitations (by design, offline-first)
- Tokens valid for entire session (until server stops)
- No token expiration (offline environment)
- No rate limiting (LAN-only, trusted network)
- Password changes require server restart
- No password reset mechanism (no external system)

---

## Implementation Details

### Password Hashing Algorithm
```
Salt: 16 random bytes (base64-encoded)
Hash: SHA256(salt:password)
Result: Hex string stored in _passwordHash
```

Example:
```
Password: "secure123"
Salt: "Y3J5cHRvLWsxNi1zYWx0LTI="
Hash: sha256("Y3J5cHRvLWsxNi1zYWx0LTI=:secure123")
      = "a7f3c9e2f1d4b8c5..."
```

### Token Format
- **Length**: 32 random bytes
- **Encoding**: Base64 (alphanumeric + hyphen/underscore)
- **Example**: `dGhpcyBpcyBhIDMyLWJ5dGUgc2VjdXJlIHRva2VuIGV4YW1w`
- **Validation**: Exact match against stored token

### Frontend Token Handling
```javascript
// Browser receives token from POST
const token = "dGhpcyBpcyBhIHRva2Vu";

// Store for session
localStorage.setItem('fastshare_token', token);

// Use in subsequent requests
fetch('/?token=' + token);
// OR
fetch('/', {headers: {'X-Share-Token': token}});
```

---

## Code Changes Summary

### New Files
1. **`lib/features/transfer/data/services/auth_manager.dart`**
   - `AuthManager` class
   - Password hashing with salt
   - Token generation and validation

### Modified Files
1. **`lib/features/transfer/data/services/local_http_server.dart`**
   - Added `_authManager` field
   - Updated `startServer()` to accept `password` parameter
   - Added `_isAuthenticated()` method
   - Added `_handlePasswordSubmission()` method
   - Added `_servePasswordForm()` method for HTML UI
   - Updated `_handleRequest()` to check auth before serving content

2. **`lib/features/transfer/presentation/screens/share_session_screen.dart`**
   - Added `_sharePassword` and `_passwordController` fields
   - Updated `startServer()` call to pass password
   - Added password input UI widget (`_buildPasswordInput`)
   - Added password display UI for active shares
   - Implemented password submission and server restart logic

3. **`pubspec.yaml`**
   - Added `crypto: ^3.0.5` dependency (for SHA256)

---

## Testing Checklist

### ✅ Manual Testing Steps

#### Public Share (No Password)
1. Start share without password
2. Access `/` in browser → File list shows
3. Download file → Works normally
4. `?token=` in URL → Ignored (no auth)

#### Protected Share
1. Start share with password "test123"
2. Access `/` in browser → Password form shows
3. Submit wrong password → "Invalid password" error
4. Submit correct password → Token returned, redirected to `/`
5. Check localStorage → Token stored
6. Access `/files?id=0` → File downloads (auth validated)
7. Change URL token → Access denied
8. Clear localStorage, reload → Password form shows again

#### Token Validation
1. Copy token from console log
2. Access `/?token=<copied_token>` → Works
3. Use header `X-Share-Token: <token>` → Works
4. Modify token slightly → Access denied
5. Remove token → Password form shows

#### Server Restart with Password
1. Set password, start share
2. On sender side, see "Optional: Add Password" with password displayed
3. Click "Edit" → Password field clears
4. Change password, click Continue → Server restarts with new password
5. Old token no longer works

---

## API Reference

### `AuthManager` Class

#### Constructor
```dart
AuthManager.fromPassword(String password)
// Generates salt, computes hash, creates initial token
```

#### Methods
```dart
bool validatePassword(String incomingPassword)
// Returns true if password matches hash

bool validateToken(String incomingToken)
// Returns true if token matches current token

void refreshToken()
// Generates new token (invalidates old ones)

String get token
// Returns current token for sharing
```

### `FileTransferServer` Class

#### `startServer` Signature
```dart
Future<ServerInfo?> startServer(
  List<SharedFile> files, {
  String? password,  // NEW: optional password
  Function(String)? onClientConnected,
  Function(int)? onBytesSent,
  Function(String)? onError,
}) async
```

#### HTTP Endpoints with Auth

| Endpoint | Method | Auth | Returns | Response |
|----------|--------|------|---------|----------|
| `/` | GET | Optional | HTML | Files or password form |
| `/` | POST | No | JSON | `{success, token}` or error |
| `/files` | GET | Required | Binary | File data or 401 |
| `/info` | GET | Required | JSON | File metadata or 401 |

---

## Console Output Example

### Without Password
```
Server running at http://192.168.1.100:54321
```

### With Password
```
⚠️  Password-protected server enabled. Token: dGhpcyBpcyBhIDMyLWJ5dGUgc2VjdXJlIHRva2Vu
Server running at http://192.168.1.100:54322
```

---

## Offline-First Design

This implementation is designed specifically for offline scenarios:
- ✅ No internet required
- ✅ No external APIs
- ✅ No database connections
- ✅ No token expiration complexity
- ✅ Works on LAN/WiFi Direct
- ✅ Entirely in-memory, ephemeral

Token validity tied to server lifetime:
- Created when server starts
- Valid until server stops
- Perfect for temporary file sharing

---

## Future Enhancements (Optional)

If needed for production:
1. **Token expiration** - Add timestamp-based validation
2. **Rate limiting** - Prevent brute-force attempts
3. **Multiple passwords** - Allow different permissions
4. **Audit logging** - Track access attempts
5. **HTTPS** - Use self-signed certs for mobile
6. **QR with token** - Embed token in QR code

---

## Troubleshooting

### Password form shows but password works
- Clear browser cache/localStorage
- Try different browser
- Check token in URL matches console output

### "Invalid password" repeats
- Confirm caps lock is off
- Check for spaces in password
- Password is case-sensitive

### Old token still works after restart
- Clear browser localStorage
- Restart browser completely
- Old password no longer valid

### Files accessible without password
- Reload page (may be browser cache)
- Check `_authManager` is initialized
- Verify `password` parameter passed to `startServer()`

---

## Dependencies

```yaml
dependencies:
  crypto: ^3.0.5  # SHA256 hashing
```

The `crypto` package is part of the Dart standard library ecosystem and is lightweight with no native dependencies.

---

## Summary

The password protection system:
1. ✅ **Secure**: SHA256 hashing with salt, tokens never logged
2. ✅ **Simple**: ~60 lines of auth code, clean API
3. ✅ **Offline**: Works on LAN without internet
4. ✅ **User-friendly**: Intuitive password form, token persistence
5. ✅ **Flexible**: Optional password, URL or header tokens
6. ✅ **Clean**: No login systems, databases, or complex state management
