import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseFirestore? _firestore;
  UserModel? _currentUser;
  bool _isLoading = false;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  
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
        if (updatedUser.totalCash != currentUser.totalCash ||
            updatedUser.todayCharCount != currentUser.todayCharCount) {
          _currentUser = updatedUser;
          notifyListeners();
        }
      }
    });
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

  Future<void> updateTypingCount(int count) async {
    if (_currentUser == null || count <= 0) return;

    try {
      // Calculate new values
      final currentUser = _currentUser!;
      final newTodayCharCount = currentUser.todayCharCount + count;
      
      // Calculate cash earned, but cap at 100 per day
      final currentCashFromChars = currentUser.todayCharCount ~/ 10;
      final newCashFromChars = newTodayCharCount ~/ 10;
      final maxDailyCash = 100;
      
      final maxCashToAdd = math.max(0, maxDailyCash - currentCashFromChars);
      final cashToAdd = (newCashFromChars - currentCashFromChars).clamp(0, maxCashToAdd);
      
      final updatedUser = currentUser.copyWith(
        todayCharCount: newTodayCharCount,
        totalCash: currentUser.totalCash + cashToAdd,
      );

      // Update local state first for immediate UI response
      _currentUser = updatedUser;
      notifyListeners();

      // Update Firestore
      if (_firestore != null) {
        await _firestore.collection('users').doc(updatedUser.id).update({
          'todayCharCount': updatedUser.todayCharCount,
          'totalCash': updatedUser.totalCash,
        });
      }
    } catch (e) {
      debugPrint('타이핑 카운트 업데이트 에러: $e');
      // Revert local state on error - restore to original state
      _currentUser = currentUser;
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

      // UI 즉시 업데이트
      _currentUser = updatedUser;
      notifyListeners();

      // Firestore 동기화
      if (_firestore != null) {
        try {
          await _firestore.collection('users').doc(currentUser.id).update({
            'collectedCash': updatedUser.collectedCash,
            'totalCash': updatedUser.totalCash,
          });
        } catch (firestoreError) {
          debugPrint('Firestore 업데이트 에러: $firestoreError');
        }
      }
    } catch (e) {
      debugPrint('캐시 수집 에러: $e');
      // 에러 시 상태 롤백
      _currentUser = currentUser.copyWith(
        collectedCash: currentUser.collectedCash - 1,
        totalCash: currentUser.totalCash - 1,
      );
      notifyListeners();
    }
  }

  void resetDailyCount() {
    if (_currentUser == null) return;
    
    final currentUser = _currentUser!;
    _currentUser = currentUser.copyWith(
      todayCharCount: 0,
      collectedCash: 0,
      // totalCash는 초기화하지 않음 (구매할 때까지 유지)
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}