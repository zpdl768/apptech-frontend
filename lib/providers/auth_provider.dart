import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// AppTech Firebase 인증 프로바이더
/// Firebase Authentication을 통한 사용자 로그인/회원가입/로그아웃을 관리하는 상태 관리 클래스
/// ChangeNotifier를 상속하여 Provider 패턴으로 전역 인증 상태를 제공
/// 이메일/비밀번호 기반 인증과 인증 상태 변화 감지 기능을 포함
class AuthProvider extends ChangeNotifier {
  // ===== Firebase 인증 인스턴스 및 상태 변수 =====
  
  /// Firebase Authentication 인스턴스
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// 현재 로그인된 사용자 정보 (로그인되지 않은 경우 null)
  User? _user;
  
  /// 인증 작업(로그인/회원가입) 진행 중 여부를 나타내는 로딩 상태
  bool _isLoading = false;
  
  /// Firebase 초기화 중 여부를 나타내는 상태 (앱 시작시 인증 상태 확인 중)
  bool _isInitializing = true;

  // ===== 상태 접근자 (Getter) 메서드들 =====
  
  /// 현재 로그인된 사용자 정보 반환
  User? get user => _user;
  
  /// 인증 작업 진행 중 여부 반환 (UI에서 로딩 표시에 사용)
  bool get isLoading => _isLoading;
  
  /// Firebase 초기화 중 여부 반환 (스플래시 화면 표시에 사용)
  bool get isInitializing => _isInitializing;
  
  /// 사용자 로그인 상태 반환 (true: 로그인됨, false: 로그아웃됨)
  bool get isAuthenticated => _user != null;

  // ===== 생성자 및 인증 상태 리스너 =====
  
  /// AuthProvider 생성자
  /// Firebase Authentication의 인증 상태 변화를 실시간으로 감지하는 리스너 설정
  /// 사용자가 다른 기기에서 로그인/로그아웃하거나 토큰이 만료되어도 자동으로 상태 업데이트
  AuthProvider() {
    // Firebase 인증 상태 변화 감지 리스너 설정
    _auth.authStateChanges().listen((User? user) {
      _user = user;                    // 사용자 정보 업데이트
      _isInitializing = false;         // 초기화 완료 상태로 변경
      notifyListeners();               // UI에 상태 변화 알림
    });
  }

  // ===== 이메일/비밀번호 로그인 메서드 =====
  
  /// 이메일과 비밀번호를 사용한 로그인 처리 메서드
  /// [email]: 사용자 이메일 주소
  /// [password]: 사용자 비밀번호
  /// Returns: 로그인 성공시 true, 실패시 false
  /// 
  /// 로그인 프로세스:
  /// 1. 로딩 상태 활성화 → 2. Firebase 로그인 시도 → 3. 성공시 사용자 정보 저장 → 4. 로딩 상태 해제
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;               // 로딩 상태 시작
      notifyListeners();               // UI에 로딩 상태 알림

      // Firebase Authentication으로 로그인 시도
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,                  // 입력받은 이메일
        password: password,            // 입력받은 비밀번호
      );
      
      _user = credential.user;         // 로그인 성공시 사용자 정보 저장
      return true;                     // 성공 반환
    } catch (e) {
      debugPrint('로그인 에러: $e');    // 콘솔에 에러 로그 출력 (개발용)
      return false;                    // 실패 반환
    } finally {
      _isLoading = false;              // 로딩 상태 종료
      notifyListeners();               // UI에 최종 상태 알림
    }
  }

  // ===== 이메일/비밀번호 회원가입 메서드 =====
  
  /// 이메일과 비밀번호를 사용한 회원가입 처리 메서드
  /// [email]: 사용자 이메일 주소 (Firebase에서 유효성 검사)
  /// [password]: 사용자 비밀번호 (Firebase에서 보안 정책 검사)
  /// Returns: 회원가입 성공시 true, 실패시 false
  /// 
  /// 회원가입 프로세스:
  /// 1. 로딩 상태 활성화 → 2. Firebase 계정 생성 → 3. 성공시 자동 로그인 → 4. 로딩 상태 해제
  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;               // 로딩 상태 시작
      notifyListeners();               // UI에 로딩 상태 알림

      // Firebase Authentication으로 새 계정 생성
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,                  // 가입할 이메일
        password: password,            // 설정할 비밀번호
      );
      
      _user = credential.user;         // 회원가입 성공시 자동으로 로그인된 사용자 정보 저장
      return true;                     // 성공 반환
    } catch (e) {
      debugPrint('회원가입 에러: $e');   // 콘솔에 에러 로그 출력 (이메일 중복, 비밀번호 규칙 위반 등)
      return false;                    // 실패 반환
    } finally {
      _isLoading = false;              // 로딩 상태 종료
      notifyListeners();               // UI에 최종 상태 알림
    }
  }

  // ===== 로그아웃 메서드 =====
  
  /// 현재 로그인된 사용자를 로그아웃 처리하는 메서드
  /// Firebase 세션 종료와 로컬 사용자 상태 초기화를 동시에 수행
  /// 
  /// 로그아웃 프로세스:
  /// 1. Firebase 세션 종료 → 2. 로컬 사용자 정보 삭제 → 3. UI에 상태 변화 알림
  Future<void> signOut() async {
    await _auth.signOut();             // Firebase에서 로그아웃 (서버 세션 종료)
    _user = null;                      // 로컬 사용자 정보 초기화
    notifyListeners();                 // UI에 로그아웃 상태 알림 (로그인 화면으로 이동)
  }
}