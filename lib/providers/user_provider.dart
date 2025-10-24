import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../services/functions_service.dart';
import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore? _firestore;
  UserModel? _currentUser;
  bool _isLoading = false;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  // 에러 상태 관리
  String? _lastError;
  bool _isDailyLimitReached = false;

  // Provider가 dispose 되었는지 추적
  bool _mounted = true;
  bool get mounted => _mounted;
  
  /// 가장 최근 에러 메시지
  String? get lastError => _lastError;
  
  /// 일일 캐시 한도 도달 여부
  bool get isDailyLimitReached => _isDailyLimitReached;
  
  UserProvider() : _firestore = _initFirestore();
  
  static FirebaseFirestore? _initFirestore() {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore initialization failed, running in demo mode: $e');
      return null;
    }
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  
  /// 에러 상태를 클리어하는 메서드
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
  
  /// 에러 상태를 설정하는 메서드
  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }
  
  /// 일일 캐시 한도 상태를 업데이트하는 메서드
  void _updateDailyLimitStatus() {
    if (_currentUser != null) {
      final wasLimitReached = _isDailyLimitReached;
      _isDailyLimitReached = _currentUser!.dailyCashEarned >= 800;
      
      // 한도 도달 상태가 변경된 경우에만 알림
      if (!wasLimitReached && _isDailyLimitReached) {
        _setError('일일 캐시 한도 800캐시에 도달했습니다! 내일 0시에 리셋됩니다.');
      }
    }
  }

  Future<void> loadUserData(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_firestore != null) {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          _currentUser = UserModel.fromFirestore(doc);
        } else {
          // Create new user if doesn't exist
          _currentUser = UserModel(
            id: userId,
            email: '',
            totalCash: 0,
            todayCharCount: 0,
            collectedCash: 0,
            dailyCashEarned: 0,
            boxStates: List.generate(10, (index) => BoxState.locked), // 10개 상자 모두 잠김 상태로 초기화
            createdAt: DateTime.now(),
          );
          await createUser(_currentUser!);
        }
        _setupRealtimeListener(userId);
      } else {
        // Firestore가 null인 경우 (초기화 실패)
        throw Exception('Firestore not initialized');
      }
    } catch (e) {
      debugPrint('사용자 데이터 로드 에러: $e');
      // 에러 발생 시 사용자 상태를 null로 유지
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupRealtimeListener(String userId) {
    if (_firestore == null) return;

    _userSubscription?.cancel();
    _userSubscription = _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && _currentUser != null) {
        final updatedUser = UserModel.fromFirestore(snapshot);
        final currentUser = _currentUser!;

        // ===== 필드별 선택적 동기화 전략 =====
        // todayCharCount: 로컬 전용 (타이핑 중 충돌 방지) - 서버 무시
        // totalCash, dailyCashEarned: 서버 검증 값만 반영
        // boxStates: 서버 상태 반영

        bool needsUpdate = false;
        UserModel newUser = currentUser;

        // 1. totalCash: 서버 검증 값만 반영 (Functions에서 업데이트)
        if (updatedUser.totalCash != currentUser.totalCash) {
          debugPrint('🔄 서버 totalCash 동기화: ${currentUser.totalCash} → ${updatedUser.totalCash}');
          newUser = newUser.copyWith(totalCash: updatedUser.totalCash);
          needsUpdate = true;
        }

        // 2. dailyCashEarned: 서버 검증 값만 반영 (Functions에서 업데이트)
        if (updatedUser.dailyCashEarned != currentUser.dailyCashEarned) {
          debugPrint('🔄 서버 dailyCashEarned 동기화: ${currentUser.dailyCashEarned} → ${updatedUser.dailyCashEarned}');
          newUser = newUser.copyWith(dailyCashEarned: updatedUser.dailyCashEarned);
          needsUpdate = true;
        }

        // 3. boxStates: 서버 상태 반영
        if (_boxStatesChanged(updatedUser.boxStates, currentUser.boxStates)) {
          debugPrint('🔄 서버 boxStates 동기화');
          newUser = newUser.copyWith(boxStates: updatedUser.boxStates);
          needsUpdate = true;
        }

        // 4. todayCharCount: 로컬 전용 - 서버 무시 (타이핑 중 충돌 방지)
        // 서버의 todayCharCount는 절대 반영하지 않음 (로컬에서만 관리)

        // 5. collectedCash: 서버 상태 반영 (캐시 수집용)
        if (updatedUser.collectedCash != currentUser.collectedCash) {
          debugPrint('🔄 서버 collectedCash 동기화: ${currentUser.collectedCash} → ${updatedUser.collectedCash}');
          newUser = newUser.copyWith(collectedCash: updatedUser.collectedCash);
          needsUpdate = true;
        }

        if (needsUpdate) {
          _currentUser = newUser;
          _updateDailyLimitStatus();
          notifyListeners();
        }
      }
    });
  }
  
  /// 상자 상태 배열이 변경되었는지 확인하는 헬퍼 메서드
  bool _boxStatesChanged(List<BoxState> newStates, List<BoxState> oldStates) {
    if (newStates.length != oldStates.length) return true;
    
    for (int i = 0; i < newStates.length; i++) {
      if (newStates[i] != oldStates[i]) return true;
    }
    return false;
  }

  Future<void> createUser(UserModel user) async {
    if (_firestore == null) {
      _currentUser = user;
      notifyListeners();
      return;
    }
    
    try {
      await _firestore.collection('users').doc(user.id).set(user.toFirestore());
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      debugPrint('사용자 생성 에러: $e');
    }
  }

  // Firestore 쓰기 디바운싱을 위한 타이머
  Timer? _firestoreDebounceTimer;

  Future<void> updateTypingCount(int count) async {
    if (_currentUser == null || count <= 0) return;

    try {
      final currentUser = _currentUser!;
      final newTodayCharCount = currentUser.todayCharCount + count;

      // Update reward box states based on new typing count
      final updatedBoxStates = _updateBoxStates(newTodayCharCount, currentUser.boxStates);

      // ===== 타이핑 카운트와 상자 상태만 업데이트 =====
      // totalCash는 절대 변경하지 않음 (홈 화면에서 코인 터치 시에만 증가)
      // readyCash는 홈 화면에서 (todayCharCount ÷ 10 - collectedCash)로 실시간 계산됨
      final optimisticUser = currentUser.copyWith(
        todayCharCount: newTodayCharCount,
        boxStates: updatedBoxStates,
      );

      _currentUser = optimisticUser;
      notifyListeners();

      // ===== Firestore 쓰기 디바운싱 (1초) =====
      // 연속 타이핑 시 Firestore 쓰기를 1초마다만 실행하여 부하 감소
      // todayCharCount는 로컬 전용이므로 리스너와 충돌 없음
      _firestoreDebounceTimer?.cancel();
      _firestoreDebounceTimer = Timer(Duration(seconds: 1), () async {
        if (_firestore != null && _currentUser != null) {
          try {
            await _firestore.collection('users').doc(_currentUser!.id).update({
              'todayCharCount': _currentUser!.todayCharCount,
              'boxStates': _currentUser!.boxStates.map((state) => state.index).toList(),
            });
            debugPrint('✅ Firestore 타이핑 카운트 업데이트 완료');
          } catch (error) {
            debugPrint('⚠️ Firestore 업데이트 에러: $error');
          }
        }
      });
    } catch (e) {
      debugPrint('타이핑 카운트 업데이트 에러: $e');
      // Revert local state on error - restore to original state
      _currentUser = _currentUser;
      notifyListeners();
    }
  }

  /// 사용자가 동전을 터치하여 캐시를 수집하는 메서드
  Future<void> collectCash() async {
    if (_currentUser == null) return;

    final currentUser = _currentUser!;
    final readyCash = (currentUser.todayCharCount ~/ 10) - currentUser.collectedCash;
    if (readyCash <= 0) return; // 수집할 캐시가 없으면 종료

    try {
      // collectedCash +1, totalCash +1 동시 증가
      final updatedUser = currentUser.copyWith(
        collectedCash: currentUser.collectedCash + 1,
        totalCash: currentUser.totalCash + 1,
      );

      // UI 즉시 업데이트 (낙관적 업데이트)
      _currentUser = updatedUser;
      _updateDailyLimitStatus();
      notifyListeners();

      // Firestore 동기화
      // 리스너가 collectedCash, totalCash를 동기화하므로 플래그 불필요
      if (_firestore != null) {
        try {
          await _firestore.collection('users').doc(currentUser.id).update({
            'collectedCash': updatedUser.collectedCash,
            'totalCash': updatedUser.totalCash,
          });
          debugPrint('✅ Firestore 캐시 수집 업데이트 완료');
        } catch (firestoreError) {
          debugPrint('⚠️ Firestore 업데이트 에러: $firestoreError');
          // 에러 시 상태 롤백
          _currentUser = currentUser;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('⚠️ 캐시 수집 에러: $e');
      // 에러 시 상태 롤백
      _currentUser = currentUser;
      notifyListeners();
    }
  }

  void resetDailyCount() {
    if (_currentUser == null) return;
    
    final currentUser = _currentUser!;
    _currentUser = currentUser.copyWith(
      todayCharCount: 0,
      collectedCash: 0,
      dailyCashEarned: 0,
      boxStates: List.generate(10, (index) => BoxState.locked), // 모든 상자를 잠김 상태로 초기화
      lastResetDate: DateTime.now(),
    );
    notifyListeners();
  }

  // ===== 리워드 광고 및 상자 상태 관리 메서드 =====
  
  /// 타이핑 카운트에 따라 상자 상태를 업데이트하는 메서드
  /// [typingCount]: 현재 타이핑한 글자 수
  /// [currentBoxStates]: 현재 상자 상태 배열
  /// Returns: 업데이트된 상자 상태 배열
  List<BoxState> _updateBoxStates(int typingCount, List<BoxState> currentBoxStates) {
    final updatedStates = List<BoxState>.from(currentBoxStates);
    
    // 각 상자별로 활성화 조건 확인 (100글자, 200글자, ..., 1000글자)
    for (int i = 0; i < 10; i++) {
      final requiredChars = (i + 1) * 100;
      
      // 충분히 타이핑했고 현재 잠긴 상태인 경우에만 활성화
      if (typingCount >= requiredChars && updatedStates[i] == BoxState.locked) {
        updatedStates[i] = BoxState.available;
      }
    }
    
    return updatedStates;
  }
  
  /// 리워드 광고 시청 완료 후 캐시를 지급하는 메서드
  /// Firebase Functions를 통해 800캐시 한도 검증 후 지급
  /// [boxIndex]: 시청한 상자의 인덱스 (0~9)
  /// Returns: 지급된 캐시 금액 (8~11 사이의 랜덤값, 실패 시 0)
  Future<int> completeRewardAd(int boxIndex) async {
    if (_currentUser == null || boxIndex < 0 || boxIndex >= 10) return 0;
    
    final currentUser = _currentUser!;
    
    // 해당 상자가 사용 가능한 상태인지 확인
    if (currentUser.boxStates[boxIndex] != BoxState.available) {
      debugPrint('상자 $boxIndex는 사용할 수 없는 상태입니다: ${currentUser.boxStates[boxIndex]}');
      return 0;
    }
    
    try {
      // 8~11 사이의 랜덤 캐시 지급
      final random = math.Random();
      final rewardCash = 8 + random.nextInt(4); // 8, 9, 10, 11 중 하나
      
      // Firebase Functions를 통해 캐시 획득 검증 (800캐시 한도 체크)
      final result = await FunctionsService().earnCashFromAd(rewardCash);
      
      if (!result['success'] || !result['allowed']) {
        // 한도 도달 시 사용자에게 알림
        final errorMessage = result['message'] ?? '캐시 획득에 실패했습니다.';
        _setError(errorMessage);
        debugPrint('캐시 획득 한도 도달: $errorMessage');
        return 0; // 캐시 지급 실패
      }
      
      // 상자 상태를 완료로 변경
      final updatedBoxStates = List<BoxState>.from(currentUser.boxStates);
      updatedBoxStates[boxIndex] = BoxState.completed;

      // Functions에서 검증된 캐시 값으로 UI 업데이트
      final updatedUser = currentUser.copyWith(
        totalCash: result['newTotalCash'],
        dailyCashEarned: result['newDailyCashEarned'],
        boxStates: updatedBoxStates,
      );

      // UI 즉시 업데이트 (낙관적 업데이트)
      _currentUser = updatedUser;
      _updateDailyLimitStatus();
      notifyListeners();

      // Firestore는 Functions에서 이미 업데이트됨
      // 상자 상태만 추가로 업데이트
      // 리스너가 boxStates를 동기화하므로 플래그 불필요
      if (_firestore != null) {
        try {
          await _firestore.collection('users').doc(currentUser.id).update({
            'boxStates': updatedUser.boxStates.map((state) => state.index).toList(),
          });
          debugPrint('✅ Firestore 상자 상태 업데이트 완료');
        } catch (error) {
          debugPrint('⚠️ Firestore 상자 상태 업데이트 에러: $error');
        }
      }

      debugPrint('✅ 리워드 광고 완료: 상자 $boxIndex에서 $rewardCash 캐시 획득 (남은 일일 한도: ${result['remainingDaily']})');
      return rewardCash;
    } catch (e) {
      debugPrint('리워드 광고 완료 처리 에러: $e');
      return 0;
    }
  }
  
  /// 특정 상자가 사용 가능한지 확인하는 메서드
  /// [boxIndex]: 확인할 상자의 인덱스 (0~9)
  /// Returns: 사용 가능하면 true
  bool canUseRewardBox(int boxIndex) {
    if (_currentUser == null || boxIndex < 0 || boxIndex >= 10) return false;
    return _currentUser!.canUseBox(boxIndex);
  }
  
  /// 사용 가능한 상자들의 인덱스 목록을 반환하는 메서드
  /// Returns: 사용 가능한 상자들의 인덱스 리스트
  List<int> getAvailableBoxes() {
    if (_currentUser == null) return [];
    
    final availableBoxes = <int>[];
    for (int i = 0; i < 10; i++) {
      if (_currentUser!.boxStates[i] == BoxState.available) {
        availableBoxes.add(i);
      }
    }
    return availableBoxes;
  }
  
  /// 완료된 상자들의 개수를 반환하는 메서드
  /// Returns: 완료된 상자의 개수
  int getCompletedBoxCount() {
    if (_currentUser == null) return 0;
    
    return _currentUser!.boxStates.where((state) => state == BoxState.completed).length;
  }

  @override
  void dispose() {
    _mounted = false;
    _userSubscription?.cancel();
    _firestoreDebounceTimer?.cancel();
    super.dispose();
  }
}