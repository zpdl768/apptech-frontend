# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**AppTech** is a Flutter application that allows users to earn virtual cash (캐시) through typing. Users can accumulate cash through two main methods:

1. **Typing System**: Earn 1 cash for every 10 characters typed (max 100 cash/day)
2. **Reward Ads**: Watch ads through 10 unlockable boxes to earn 8-11 random cash per ad (max 700 cash/day from ads)
3. **Daily Limit**: Combined limit of 800 cash per day (100 from typing + 700 from ads)
4. **Gifticon Store**: Purchase gift cards (Starbucks, McDonald's, CGV, etc.) using accumulated cash

### Tech Stack

- **Frontend**: Flutter + Dart
- **Backend**: Firebase (Authentication, Firestore, Functions)
- **Monetization**: Google AdMob (Banner Ads, Rewarded Ads)
- **State Management**: Provider pattern
- **Development**: Firebase Emulator Suite for local testing

### Key Features

- 🔐 **Firebase Authentication**: Email/password login with password reset
- ⌨️ **Real-time Typing Tracking**: 50ms debouncing with Firestore sync
- 📦 **10-Box Reward System**: Unlock boxes every 100 characters (locked → available → completed)
- 📺 **AdMob Integration**: Banner ads + Rewarded ads with 8-11 random cash rewards
- 🏪 **Gifticon Store**: 6 gift cards (1,000 - 10,000 cash)
- 📊 **User Statistics**: Daily char count, total cash, progress tracking
- 🔄 **Daily Reset**: Automatic reset at midnight via Firebase Functions
- 🛡️ **800 Cash Limit**: Server-side validation via Firebase Functions

## Directory Structure

```
apptech/
└── frontend/               # Flutter application
    ├── lib/
    │   ├── main.dart                               # App entry point, Firebase/AdMob init
    │   ├── models/
    │   │   └── user_model.dart                     # User data model (cash, typing, boxes)
    │   ├── providers/
    │   │   ├── auth_provider.dart                  # Firebase Authentication management
    │   │   └── user_provider.dart                  # User data & Firestore sync
    │   ├── screens/
    │   │   ├── login_screen.dart                   # Login screen
    │   │   ├── register_screen.dart                # Registration with password strength
    │   │   ├── forgot_password_screen.dart         # Password reset
    │   │   ├── home_screen.dart                    # Main screen (cash, ads, boxes)
    │   │   ├── main_navigation_screen.dart         # Bottom tab navigation (unused)
    │   │   ├── keyboard_screen.dart                # Typing screen (main cash earning)
    │   │   ├── store_screen.dart                   # Gifticon store
    │   │   └── profile_screen.dart                 # My page (stats, settings, logout)
    │   ├── widgets/
    │   │   ├── auth_wrapper.dart                   # Auth state routing
    │   │   └── password_strength_indicator.dart    # Password strength UI
    │   └── services/
    │       ├── functions_service.dart              # Firebase Functions (daily reset, 800 limit)
    │       ├── reward_ad_service.dart              # Google AdMob Rewarded Ads
    │       └── api_service.dart                    # (Currently unused)
    ├── test/                                        # Widget tests
    ├── android/                                     # Android platform code
    ├── ios/                                         # iOS platform code
    └── web/                                         # Web platform code
```

## Core Features

### 1. Typing Cash System (타이핑 캐시 시스템)

**Rules:**
- 10 characters = 1 cash
- Daily limit: 100 cash from typing
- Real-time character counting with 50ms debouncing
- Instant Firestore sync on each typing session

**Implementation:**
- `keyboard_screen.dart`: TextEditingController with debouncing
- `user_provider.dart`: `updateTypingCount()` method
- Firebase Functions: Validates 800 daily limit before accepting

**Data Flow:**
```
User types → 50ms debounce → updateTypingCount() → Firestore update → Firebase Functions validate → Success/Error
```

### 2. Reward Ad Box System (리워드 광고 상자 시스템)

**10-Box Unlocking System:**
- Box 1: Unlocks at 100 characters
- Box 2: Unlocks at 200 characters
- ...
- Box 10: Unlocks at 1,000 characters (piggy bank icon)

**Box States:**
```dart
enum BoxState {
  locked,      // Gray: Not enough characters typed
  available,   // Golden: Ready to watch ad
  completed,   // Green: Ad watched, cash collected
}
```

**Reward Mechanism:**
- Watch rewarded ad → Earn 8-11 random cash (balanced for gameplay)
- Daily limit: Max 10 boxes × ~10 cash = ~100 cash (but capped at 700 from ads)
- Box states reset daily at midnight

**Implementation:**
- `home_screen.dart`: Box UI with state-based colors
- `reward_ad_service.dart`: AdMob rewarded ad loading/showing
- `user_provider.dart`: `completeRewardAd()` method
- Firebase Functions: Validates 800 daily limit

### 3. Daily 800 Cash Limit (일일 한도 관리)

**Limit Breakdown:**
- Typing: max 100 cash/day (1,000 characters)
- Reward Ads: max 700 cash/day (~70 ads)
- **Total: 800 cash/day**

**Server-Side Validation:**
- All cash earning goes through Firebase Functions `validateCashEarning()`
- Functions check `dailyCashEarned` before allowing new cash
- Returns `allowed: true/false` with remaining daily amount
- Prevents client-side tampering

**Implementation:**
```dart
// functions_service.dart
Future<Map<String, dynamic>> validateCashEarning(int amount) async {
  // Calls Firebase Function 'validateCashEarning'
  // Returns: { allowed, newTotalCash, newDailyCashEarned, message }
}
```

### 4. Gifticon Store (기프티콘 상점)

**Available Gift Cards:**
1. Starbucks Americano - 1,000 cash
2. Twosome Place Drink - 1,500 cash
3. McDonald's Set - 3,000 cash
4. Lotteria Set - 2,500 cash
5. CGV Movie Ticket - 5,000 cash
6. Cultureland Gift Card - 10,000 cash

**Purchase Flow (Planned):**
```
User clicks purchase → Check balance → Verify → Purchase confirmation dialog → Deduct cash → Record purchase history
```

**Implementation:**
- `store_screen.dart`: 2-column grid view with purchase dialogs
- `user_provider.dart`: `purchaseGifticon()` method (to be implemented)
- Firestore: Transaction to ensure atomic cash deduction

### 5. Daily Reset System (일일 리셋)

**Reset Mechanism:**
- Runs daily at midnight (00:00 KST)
- Firebase Functions scheduled function
- Resets: `todayCharCount`, `collectedCash`, `boxStates`, `dailyCashEarned`
- Keeps: `totalCash`, `email`, `createdAt`

**Anti-Cheat Protection:**
- Server stores `lastResetDate`
- Detects time manipulation (backwards time)
- Locks account if suspicious activity detected

**Implementation:**
```javascript
// Firebase Functions (scheduled)
exports.scheduledDailyReset = functions.pubsub.schedule('0 0 * * *')
  .timeZone('Asia/Seoul')
  .onRun(async (context) => {
    // Reset all users' daily data
  });
```

## File Descriptions

### Models

#### `user_model.dart`
Complete user data model with all properties and methods.

**Properties:**
```dart
class UserModel {
  final String id;                    // Firebase UID
  final String email;                 // User email
  final int totalCash;                // Total accumulated cash (never resets)
  final int todayCharCount;           // Today's typing count (resets daily)
  final int collectedCash;            // Cash collected from typing today (resets daily)
  final List<BoxState> boxStates;     // 10 reward box states (resets daily)
  final DateTime lastUpdate;          // Last Firestore update timestamp
  final DateTime createdAt;           // Account creation date
}
```

**Key Methods:**
- `getBoxState(int index)`: Returns state of box at given index (locked/available/completed)
- `toMap()`: Converts to Map for Firestore storage
- `fromFirestore()`: Creates UserModel from Firestore document
- `copyWith()`: Immutable update pattern for state changes

### Providers

#### `auth_provider.dart`
Manages Firebase Authentication state and operations.

**Key Methods:**
```dart
class AuthProvider extends ChangeNotifier {
  User? get user;                                          // Current Firebase user
  Future<bool> signInWithEmailAndPassword();               // Login
  Future<bool> createUserWithEmailAndPassword();           // Register
  Future<bool> sendPasswordResetEmail();                   // Password reset
  Future<void> signOut();                                  // Logout
  Stream<User?> get authStateChanges;                      // Auth state stream
}
```

#### `user_provider.dart`
Manages user data and Firestore synchronization. **Most complex file in the project.**

**Key Methods:**
```dart
class UserProvider extends ChangeNotifier {
  UserModel? get currentUser;                              // Current user data
  Future<void> loadUserData(String uid);                   // Load from Firestore
  Future<void> updateTypingCount(int addedChars);          // Add typing characters
  Future<void> collectCash();                              // Collect ready cash
  Future<int> completeRewardAd(int boxIndex);              // Complete ad & earn cash
  Future<void> purchaseGifticon(String name, int price);   // Purchase gift (TODO)

  // Auto-save to Firestore on every change
  // Real-time listener for Firestore updates
}
```

**Complex Logic:**
- 50ms debouncing for typing events to reduce Firestore writes
- Automatic Firestore sync on every state change
- Real-time listener to sync updates from other devices
- Error handling with user-friendly messages
- Daily limit checking before allowing cash earning

### Screens

#### `home_screen.dart`
Main screen with cash tracking, ads, and reward boxes. **Most complex UI file.**

**Features:**
- Circular progress indicator (1,000 char goal)
- Tap-to-collect cash animation (200ms bounce)
- Google AdMob banner ad (300x250 mediumRectangle)
- 10 horizontal scrolling reward boxes with state-based styling
- App guide dialog with 5 pages of instructions
- Real-time cash/character display

**Complex Logic:**
- `_animateAndCollectCash()`: Simultaneous animation + Firestore update
- `_onRewardBoxTapped()`: State-based navigation (locked/available/completed)
- `_showRewardAd()`: Loading → Display → Reward → Next ad preload
- Box state color calculation (gray/gold/green)

#### `keyboard_screen.dart`
Typing screen where users earn cash. Main cash earning method.

**Features:**
- Multi-line text input with auto-focus
- Real-time character counting
- Session cash tracking (green "+X")
- Today's total stats display
- Clear text + Force keyboard focus buttons

**Complex Logic:**
- `_onTextChanged()`: 50ms debouncing to prevent excessive Firestore writes
- Tracks only character additions (deletions don't earn cash)
- Real-time UI updates with Provider

#### `store_screen.dart`
Gifticon store with 2-column grid layout.

**Features:**
- 6 gift card products
- Purchase availability based on user cash
- Purchase confirmation dialogs
- Success dialogs after purchase

**To Be Implemented:**
- Actual purchase transaction with Firestore
- Purchase history recording
- Gift card code generation/delivery

#### `profile_screen.dart`
User profile with statistics, settings, and logout.

**Features:**
- User info card (email, join date)
- 4 stat cards (total cash, today input, today cash, progress %)
- Settings menu (app info, help, privacy policy - all placeholders)
- Logout with confirmation dialog

#### `register_screen.dart`
Registration screen with password strength validation.

**Features:**
- Email + password input with validation
- Real-time password strength indicator (very weak → strong)
- Password requirements checklist (8 chars, uppercase, lowercase, numbers, special chars)
- Toggle password visibility
- Firebase user creation + Firestore user document

#### `login_screen.dart`
Login screen with email/password authentication.

**Features:**
- Email + password input
- Input validation
- Toggle password visibility
- Navigation to register/forgot password screens

#### `forgot_password_screen.dart`
Password reset via email.

**Features:**
- Email input with validation
- Firebase password reset email sending
- Success screen with instructions
- Resend email option

### Widgets

#### `auth_wrapper.dart`
Routes users based on authentication state.

**Logic:**
```dart
Widget build(BuildContext context) {
  return StreamBuilder<User?>(
    stream: authProvider.authStateChanges,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return HomeScreen();     // Logged in → Home
      } else {
        return LoginScreen();    // Not logged in → Login
      }
    },
  );
}
```

#### `password_strength_indicator.dart`
Visual password strength indicator with checklist.

**Features:**
- Enum: `PasswordStrength` (veryWeak, weak, medium, strong)
- Progress bar (red/orange/yellow/green)
- 5 requirement checkboxes (length, uppercase, lowercase, numbers, special chars)
- Static methods for validation

### Services

#### `functions_service.dart`
Firebase Functions client for server-side operations.

**Key Methods:**
```dart
class FunctionsService {
  Future<Map<String, dynamic>> checkDailyReset();          // Check & execute daily reset
  Future<Map<String, dynamic>> validateCashEarning(int amount); // Validate 800 limit
  Future<Map<String, dynamic>> earnCashFromAd(int amount); // Earn cash from ad
  Future<Map<String, dynamic>> earnCashFromTyping(int amount); // Earn cash from typing
  Future<Map<String, dynamic>> getDailyCashStatus();       // Get remaining daily cash
  Future<bool> initializeApp();                            // App startup initialization
}
```

**Emulator Configuration:**
```dart
if (kDebugMode) {
  _functions.useFunctionsEmulator('192.168.123.66', 5001);
}
```

#### `reward_ad_service.dart`
Google AdMob rewarded ad manager.

**Key Methods:**
```dart
class RewardAdService {
  bool get isReady;                                        // Is ad loaded?
  bool get isLoading;                                      // Is ad loading?
  Future<void> loadRewardedAd();                           // Load rewarded ad
  Future<bool> showRewardedAd({                            // Show rewarded ad
    required Function(int rewardAmount) onUserEarnedReward,
    VoidCallback? onAdClosed,
    Function(String error)? onAdFailedToShow,
  });
  void dispose();                                          // Clean up resources
}
```

**Ad IDs:**
- Android: `ca-app-pub-3940256099942544/5224354917` (test)
- iOS: `ca-app-pub-3940256099942544/1712485313` (test)

**Reward Logic:**
```dart
// Ignore AdMob reward value, use 8-11 random for game balance
final randomReward = 8 + (reward.amount.toInt() % 4); // 8, 9, 10, 11
onUserEarnedReward(randomReward);
```

## Development Setup

### Prerequisites

```bash
# Install Flutter
flutter doctor

# Firebase CLI for emulator
npm install -g firebase-tools
firebase login
```

### Firebase Emulator Configuration

**IP Address:** `192.168.123.66` (Change this to your local IP)

**Ports:**
- Auth: 9099
- Firestore: 8088
- Functions: 5001

**Start Emulator:**
```bash
cd frontend
firebase emulators:start
```

**Emulator UI:**
- http://localhost:4000

**Connection Configuration (main.dart):**
```dart
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('192.168.123.66', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('192.168.123.66', 8088);
  FirebaseFunctions.instance.useFunctionsEmulator('192.168.123.66', 5001);
}
```

## Common Commands

All commands should be run from the `frontend/` directory:

### Development
```bash
cd frontend
flutter run                    # Run app in debug mode (connects to emulator)
flutter run -d chrome         # Run on web browser
flutter run --release         # Run in release mode (WARNING: connects to production Firebase!)
```

### Code Quality
```bash
flutter analyze               # Static analysis
flutter format .             # Format all Dart code
```

### Testing
```bash
flutter test                 # Run all widget tests
flutter test test/widget_test.dart  # Run specific test file
```

### Build
```bash
flutter build apk           # Build Android APK
flutter build ios           # Build iOS (requires macOS)
flutter build web           # Build for web deployment
```

### Dependencies
```bash
flutter pub get             # Install dependencies from pubspec.yaml
flutter pub upgrade         # Upgrade dependencies
flutter clean               # Clean build artifacts
```

## Data Flow

### 1. Authentication Flow

```
User enters email/password
    ↓
AuthProvider.signInWithEmailAndPassword()
    ↓
Firebase Authentication
    ↓
authStateChanges stream emits User
    ↓
AuthWrapper routes to HomeScreen
    ↓
UserProvider.loadUserData() loads Firestore data
    ↓
UI displays user cash and stats
```

### 2. Typing Cash Flow

```
User types in KeyboardScreen
    ↓
50ms debounce
    ↓
UserProvider.updateTypingCount(addedChars)
    ↓
FunctionsService.earnCashFromTyping(cash)
    ↓
Firebase Functions: validateCashEarning()
    ├─ Check dailyCashEarned < 800
    ├─ Update totalCash, dailyCashEarned
    └─ Return allowed: true/false
    ↓
If allowed:
    ├─ Update Firestore
    ├─ Notify UI (SnackBar: "🎉 X 캐시 획득!")
    └─ Update statistics
If denied:
    └─ Show daily limit reached message
```

### 3. Reward Ad Flow

```
User taps available box in HomeScreen
    ↓
RewardAdService.showRewardedAd()
    ↓
Google AdMob displays fullscreen ad
    ↓
User watches ad completely
    ↓
onUserEarnedReward(8-11 random cash)
    ↓
UserProvider.completeRewardAd(boxIndex)
    ↓
FunctionsService.earnCashFromAd(cash)
    ↓
Firebase Functions: validateCashEarning()
    ├─ Check dailyCashEarned < 800
    ├─ Update totalCash, dailyCashEarned, boxStates[index]
    └─ Return allowed: true/false
    ↓
If allowed:
    ├─ Update Firestore
    ├─ Mark box as completed (green)
    ├─ Show success SnackBar
    └─ Preload next ad
If denied:
    └─ Show daily limit reached message
```

### 4. Daily Reset Flow

```
Midnight (00:00 KST)
    ↓
Firebase Functions: scheduledDailyReset()
    ↓
For each user in Firestore:
    ├─ Reset todayCharCount = 0
    ├─ Reset collectedCash = 0
    ├─ Reset boxStates = [locked × 10]
    ├─ Reset dailyCashEarned = 0
    ├─ Update lastResetDate = today
    └─ Keep totalCash unchanged
    ↓
Next app open:
    ├─ FunctionsService.checkDailyReset()
    ├─ Detect if reset needed
    ├─ Execute reset if missed
    └─ Refresh UI
```

## Architecture

### Provider Pattern

**State Management:**
```
MaterialApp
    └── MultiProvider
            ├── AuthProvider (ChangeNotifier)
            │       └── Firebase Auth state
            └── UserProvider (ChangeNotifier)
                    └── User data & Firestore sync

Consumer widgets listen to providers and rebuild on changes
```

### Firebase Integration

**Services:**
1. **Firebase Authentication**: Email/password login
2. **Cloud Firestore**: User data storage with real-time sync
3. **Cloud Functions**: Server-side validation (800 limit, daily reset, anti-cheat)
4. **Firebase Emulator**: Local development environment

**Firestore Structure:**
```
/users/{uid}
    ├── email: string
    ├── totalCash: number
    ├── todayCharCount: number
    ├── collectedCash: number
    ├── boxStates: array[10]
    ├── dailyCashEarned: number
    ├── lastResetDate: timestamp
    ├── lastUpdate: timestamp
    └── createdAt: timestamp
```

### Real-time Synchronization

**Firestore Listeners:**
```dart
// user_provider.dart
_userSubscription = FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .snapshots()
    .listen((snapshot) {
      _currentUser = UserModel.fromFirestore(snapshot);
      notifyListeners(); // Rebuild all Consumer widgets
    });
```

**Benefits:**
- Multiple device sync
- Instant UI updates
- Offline support (Firestore cache)
- Conflict resolution

## Deployment History & Changes

### 2025-10-24: 타이핑 시스템 안정화 및 UI 개선

#### 🐛 해결된 주요 문제

**타이핑 카운트 버벅임 및 감소 현상**
- **증상**: 빠른 타이핑 시 글자 수가 10자마다 갑자기 감소하거나 튀는 현상
- **원인**: Firestore 실시간 리스너가 로컬 업데이트를 덮어쓰는 충돌 발생
- **해결**: 필드별 선택적 동기화 전략 도입
  - `todayCharCount`: 로컬 전용 관리 (서버 값 무시)
  - `totalCash`, `dailyCashEarned`: 서버 검증 값만 반영
  - `boxStates`, `collectedCash`: 양방향 동기화

**totalCash 불안정 현상**
- **증상**: 타이핑 중 상단 총 캐시가 +1/-1 반복
- **원인**: 타이핑 시 `totalCash`를 잘못 증가시키는 로직
- **해결**: 타이핑 시 `totalCash` 절대 변경 안 함 (홈 화면 코인 터치 시에만 증가)

#### 🔧 백엔드 로직 개선

**Firestore 실시간 리스너 최적화** (`user_provider.dart:110-169`)
```dart
// 필드별 선택적 동기화 전략
void _setupRealtimeListener(String userId) {
  // 1. totalCash: 서버 검증 값만 반영
  // 2. dailyCashEarned: 서버 검증 값만 반영
  // 3. boxStates: 서버 상태 반영
  // 4. todayCharCount: 로컬 전용 - 서버 무시 (충돌 방지)
  // 5. collectedCash: 서버 상태 반영
}
```

**타이핑 업데이트 로직 단순화** (`user_provider.dart:196-240`)
- 불필요한 캐시 계산 로직 제거
- `todayCharCount`와 `boxStates`만 업데이트
- `totalCash`는 절대 변경하지 않음
- 1초 디바운싱으로 Firestore 쓰기 최소화

**데이터 흐름 명확화**
```
타이핑 → todayCharCount 증가 (로컬만)
       → Firestore 저장 (1초 디바운싱)
       → readyCash = (todayCharCount ÷ 10) - collectedCash (홈 화면에서 실시간 계산)

코인 터치 → collectedCash +1
         → totalCash +1
         → Firestore 저장
```

#### 🎨 키보드 화면 UI 개선 (`keyboard_screen.dart`)

**통계 카드 단순화**
- **이전**: 3열 (오늘 입력 | 오늘 캐시 | 세션 캐시)
- **변경**: 1열 (오늘 타이핑만 표시)
- 불필요한 `_sessionCash` 변수 완전 제거

**카드 높이 축소 (50% 감소)**
- 레이아웃: 세로(Column) → 가로(Row)
- 패딩: 20px → 12px/16px
- 폰트: 32pt → 24pt
- 타이핑 영역에 더 많은 공간 확보

**최종 UI**
```
┌─────────────────────────────────────┐
│  오늘 타이핑              1000 자    │
└─────────────────────────────────────┘
```

#### ✅ 개선 효과

- 타이핑 글자 수 절대 감소 안 함 (100% 안정)
- totalCash 완전 안정화 (타이핑 중 변경 없음)
- UI 깔끔하고 공간 효율적
- Firestore 읽기/쓰기 충돌 완전 제거
- 코드 가독성 및 유지보수성 향상

#### 📁 수정된 파일

- `lib/providers/user_provider.dart`: 핵심 로직 개선 (5곳)
- `lib/screens/keyboard_screen.dart`: UI 개선 및 변수 정리

### 2025-10-23: iOS 실물 기기 배포 및 Firebase Functions 프로덕션 배포

#### 🔧 구성 변경

**Firebase 플랜 업그레이드**
- Spark (무료) → Blaze (종량제) 플랜으로 업그레이드
- Cloud Functions 사용 가능하게 됨
- 이유: 리워드 광고 캐시 적립 기능에 서버 검증 필요

**배포된 Firebase Functions (4개)**
- `validateCashEarning`: 캐시 획득 검증 및 800 일일 한도 체크 (HTTP)
- `checkDailyReset`: 앱 시작 시 일일 리셋 확인 (HTTP)
- `scheduledDailyReset`: 매일 자정 자동 리셋 실행 (스케줄)
- `fraudDetection`: 부정행위 감지 (HTTP)

**Functions Cleanup Policy 설정**
- 1일 이상 된 Docker 이미지 자동 삭제
- 목적: Container Registry 스토리지 비용 최소화

#### 🐛 해결된 문제

**리워드 광고 캐시 미적립 문제**
- 증상: 광고는 정상 표시되지만 캐시가 적립되지 않음
- 원인: Firebase Functions가 프로덕션에 배포되지 않음
- 해결: Blaze 플랜 업그레이드 후 Functions 배포 완료

#### ✅ 구현된 기능

**iOS 실물 기기 무선 디버깅**
- iPhone과 Mac을 Wi-Fi로 연결하여 개발 가능
- USB 케이블 없이 배포 및 테스트 가능

**Debug/Release 모드 자동 환경 전환**
- Debug 모드: Firebase Emulator 자동 연결 (로컬 개발)
- Release 모드: Firebase 프로덕션 자동 연결 (실제 환경)
- `kDebugMode` 플래그로 자동 전환 (`main.dart:34-49`)

**프로덕션 환경 리워드 광고 시스템**
- AdMob 테스트 광고 정상 작동
- 광고 시청 후 8-11 랜덤 캐시 적립
- Firebase Functions를 통한 서버 검증
- 일일 800 캐시 한도 자동 적용

#### 📋 테스트 완료 항목

- ✅ Firebase Authentication (로그인/회원가입)
- ✅ Firestore 데이터 읽기/쓰기
- ✅ 타이핑 캐시 적립 (10자 = 1캐시)
- ✅ 리워드 광고 시청 및 캐시 적립 (8-11 캐시)
- ✅ iOS 실물 기기 Release 모드 배포
- ✅ 무선 디버깅 연결

#### 🔍 확인 방법

**프로덕션 Firebase 연결 확인:**
1. Release 모드로 앱 실행
2. 회원가입/로그인 시도
3. Firebase Console → Authentication에서 사용자 생성 확인
4. 사용자가 생성되었다면 프로덕션 연결 성공

**Functions 배포 확인:**
- Firebase Console: https://console.firebase.google.com/project/apptech-9928c/functions
- 4개 Functions 배포 상태: Active

**빌드 모드 확인:**
```bash
# Debug 모드 (Emulator)
flutter run -d <device-id>

# Release 모드 (프로덕션)
flutter run --release -d <device-id>
```

## Known Issues & TODOs

### Current Issues
1. `main_navigation_screen.dart` exists but is unused (bottom navigation is built into `home_screen.dart`)
2. Test files are outdated (test old counter template, not actual app)
3. `api_service.dart` exists but is not used anywhere
4. Store purchase flow is not fully implemented (no Firestore transaction yet)

### TODOs
1. Implement actual gifticon purchase with Firestore transactions
2. Add purchase history screen
3. Implement gift card code generation/delivery system
4. Add social login (Google, Apple, Kakao, Naver) - planned feature
5. Add walk tracking for additional cash earning - planned feature
6. Clean up commented template code in `main.dart`
7. Update test files to match actual implementation
8. Add error recovery for failed Firestore writes
9. Implement retry logic for AdMob ad loading failures
10. Add analytics tracking (Firebase Analytics)
11. **Upgrade Node.js runtime to 20+ before 2025-10-30** (Functions deprecation warning)

## Korean Language Notes

This is a Korean-language application with:
- Korean UI text and messages
- Korean comments in code
- Korean gifticons (Starbucks, McDonald's, CGV, Cultureland)
- Korean user base assumed

All variable names and function names are in English for maintainability, but UI strings and comments are primarily in Korean.
