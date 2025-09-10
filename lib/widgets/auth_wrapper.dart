import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

/// AppTech 인증 상태 추상화 래퍼 위젯
/// 사용자의 로그인 상태에 따라 적절한 화면을 동적으로 표시하는 라우팅 위젯
/// Firebase 초기화, 로그인 상태, 로그아웃 상태를 구분하여 3가지 화면 분기 제공
/// 스플래시 화면, 로그인 화면, 메인 앱 화면 간의 자동 전환을 담당
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // ===== 메인 UI 빌드 메서드 =====
  
  /// 인증 상태에 따른 화면 라우팅을 담당하는 메인 빌드 메서드
  /// AuthProvider의 상태를 감시하여 3가지 화면 중 적절한 화면을 표시
  /// 1. 초기화 중: 스플래시 화면 → 2. 로그인됨: 메인 앱 → 3. 로그아웃: 로그인 화면
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // ===== Firebase 초기화 스플래시 화면 =====
        // Firebase Authentication 초기화 중일 때 표시되는 로딩 화면
        if (authProvider.isInitializing) {
          return Scaffold(
            backgroundColor: Colors.white,                    // 흰색 배경
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,  // 중앙 정렬
                children: [
                  // ===== 앱 로고 컨테이너 =====
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,              // 보라색 배경
                      borderRadius: BorderRadius.circular(20), // 둥근 모서리
                    ),
                    child: Icon(
                      Icons.monetization_on,                 // 코인 아이콘 (앱의 컨셉을 나타냄)
                      color: Colors.white,                   // 흰색 아이콘
                      size: 40,                              // 아이콘 크기
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // ===== 앱 이름 및 설명 =====
                  Text(
                    'AppTech',                               // 앱 이름
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,              // 보라색 텍스트
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '타이핑으로 캐시를 모으세요',         // 앱 설명/슬로건
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],               // 회색 텍스트
                    ),
                  ),
                  SizedBox(height: 40),
                  
                  // ===== 로딩 인디케이터 =====
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple), // 보라색 로딩 스피너
                  ),
                ],
              ),
            ),
          );
        }

        // ===== 로그인 상태에 따른 화면 라우팅 =====
        // Firebase 초기화 완료 후 사용자 인증 상태에 따라 화면 분기
        if (authProvider.isAuthenticated) {
          // 로그인된 상태: 메인 앱 화면으로 이동
          return HomeScreen();               // TODO: HomeScreen을 MainNavigationScreen으로 변경 필요
        } else {
          // 로그아웃된 상태: 로그인 화면으로 이동
          return LoginScreen();              // 로그인/회원가입 화면
        }
      },
    );
  }
}