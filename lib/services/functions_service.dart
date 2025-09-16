import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Functions와 통신하는 서비스 클래스
/// 일일 리셋 체크, 캐시 획득 검증, 800캐시 한도 관리를 담당
class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  /// 싱글톤 인스턴스
  static final FunctionsService _instance = FunctionsService._internal();
  factory FunctionsService() => _instance;
  FunctionsService._internal() {
    // 개발 환경에서는 에뮬레이터 사용
    if (kDebugMode) {
      _functions.useFunctionsEmulator('localhost', 5001);
      debugPrint('Firebase Functions 에뮬레이터 연결: localhost:5001');
    }
  }

  /// 일일 리셋 체크 및 실행
  /// 매일 자정에 자동으로 실행되지만, 앱 시작시에도 확인 필요
  /// Returns: 리셋이 실행되었는지 여부와 메시지
  Future<Map<String, dynamic>> checkDailyReset() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      final callable = _functions.httpsCallable('checkDailyReset');
      final result = await callable.call();
      
      debugPrint('일일 리셋 체크 결과: ${result.data}');
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (error) {
      debugPrint('Firebase Functions 에러: ${error.code} - ${error.message}');
      
      // 에러 코드에 따른 처리
      switch (error.code) {
        case 'unauthenticated':
          throw Exception('로그인이 필요합니다.');
        case 'permission-denied':
          throw Exception('의심스러운 시간 조작이 감지되었습니다.');
        default:
          throw Exception('일일 리셋 체크에 실패했습니다: ${error.message}');
      }
    } catch (error) {
      debugPrint('일일 리셋 체크 에러: $error');
      throw Exception('일일 리셋 체크 중 오류가 발생했습니다.');
    }
  }

  /// 캐시 획득 검증 (800캐시 한도 확인)
  /// 리워드 광고나 타이핑으로 캐시 획득 전에 호출
  /// [amount]: 획득하려는 캐시 양 (1~20)
  /// Returns: 획득 가능 여부와 새로운 캐시 값들
  Future<Map<String, dynamic>> validateCashEarning(int amount) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('사용자가 로그인되지 않았습니다.');
      }

      if (amount <= 0 || amount > 20) {
        throw Exception('유효하지 않은 캐시 양입니다. (1~20 사이여야 함)');
      }

      final callable = _functions.httpsCallable('validateCashEarning');
      final result = await callable.call({'amount': amount});
      
      debugPrint('캐시 획득 검증 결과: ${result.data}');
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (error) {
      debugPrint('Firebase Functions 에러: ${error.code} - ${error.message}');
      
      // 에러 코드에 따른 처리
      switch (error.code) {
        case 'unauthenticated':
          throw Exception('로그인이 필요합니다.');
        case 'permission-denied':
          throw Exception('계정이 정지되었습니다.');
        case 'invalid-argument':
          throw Exception('유효하지 않은 캐시 양입니다.');
        default:
          throw Exception('캐시 획득 검증에 실패했습니다: ${error.message}');
      }
    } catch (error) {
      debugPrint('캐시 획득 검증 에러: $error');
      throw Exception('캐시 획득 검증 중 오류가 발생했습니다.');
    }
  }

  /// 앱 시작시 호출하는 초기화 메서드
  /// 일일 리셋 체크를 수행하고 필요시 사용자 데이터를 업데이트
  /// Returns: 리셋이 발생했는지 여부
  Future<bool> initializeApp() async {
    try {
      final resetResult = await checkDailyReset();
      return resetResult['wasReset'] ?? false;
    } catch (error) {
      debugPrint('앱 초기화 에러: $error');
      // 초기화 실패해도 앱 사용은 가능하게 함
      return false;
    }
  }

  /// 리워드 광고 시청 후 캐시 획득
  /// [amount]: 광고로 획득한 캐시 양 (8~11)
  /// Returns: 획득 성공 여부와 새로운 캐시 정보
  Future<Map<String, dynamic>> earnCashFromAd(int amount) async {
    try {
      final result = await validateCashEarning(amount);
      
      if (!result['allowed']) {
        return {
          'success': false,
          'allowed': false,
          'message': result['message'],
          'remainingDaily': 800 - (result['newDailyCashEarned'] ?? 0),
        };
      }
      
      return {
        'success': true,
        'allowed': true,
        'newTotalCash': result['newTotalCash'],
        'newDailyCashEarned': result['newDailyCashEarned'],
        'message': result['message'],
        'remainingDaily': 800 - result['newDailyCashEarned'],
      };
    } catch (error) {
      return {
        'success': false,
        'allowed': false,
        'message': error.toString(),
        'remainingDaily': 0,
      };
    }
  }

  /// 타이핑으로 캐시 획득 (10글자당 1캐시)
  /// [amount]: 타이핑으로 획득한 캐시 양 (보통 1)
  /// Returns: 획득 성공 여부와 새로운 캐시 정보
  Future<Map<String, dynamic>> earnCashFromTyping(int amount) async {
    try {
      final result = await validateCashEarning(amount);
      
      if (!result['allowed']) {
        return {
          'success': false,
          'allowed': false,
          'message': result['message'],
          'remainingDaily': 800 - (result['newDailyCashEarned'] ?? 0),
        };
      }
      
      return {
        'success': true,
        'allowed': true,
        'newTotalCash': result['newTotalCash'],
        'newDailyCashEarned': result['newDailyCashEarned'],
        'message': result['message'],
        'remainingDaily': 800 - result['newDailyCashEarned'],
      };
    } catch (error) {
      return {
        'success': false,
        'allowed': false,
        'message': error.toString(),
        'remainingDaily': 0,
      };
    }
  }

  /// 현재 사용자의 일일 캐시 한도 상태 확인
  /// Returns: 남은 캐시량과 진행률 정보
  Future<Map<String, dynamic>> getDailyCashStatus() async {
    try {
      // 0캐시로 검증 요청을 보내서 현재 상태만 확인
      final result = await validateCashEarning(0);
      
      return {
        'dailyCashEarned': result['newDailyCashEarned'] ?? 0,
        'remainingDaily': 800 - (result['newDailyCashEarned'] ?? 0),
        'progress': (result['newDailyCashEarned'] ?? 0) / 800,
        'limitReached': (result['newDailyCashEarned'] ?? 0) >= 800,
      };
    } catch (error) {
      debugPrint('일일 캐시 상태 확인 에러: $error');
      return {
        'dailyCashEarned': 0,
        'remainingDaily': 800,
        'progress': 0.0,
        'limitReached': false,
      };
    }
  }
}