import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';

/// AppTech 마이페이지 화면
/// 사용자 정보, 타이핑 통계, 앱 설정, 로그아웃 기능을 제공하는 화면
/// StatelessWidget으로 구현하여 성능 최적화
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  // ===== 메인 UI 빌드 메서드 =====
  
  /// 마이페이지 화면의 UI를 구성하는 메인 빌드 메서드
  /// 포함 요소: 사용자 프로필, 통계 카드들, 설정 메뉴, 로그아웃
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경색: 흰색
      
      // ===== 상단 앱바 =====
      appBar: AppBar(
        title: Text('마이페이지', style: TextStyle(color: Colors.black)), // 검은색 제목
        backgroundColor: Colors.white,                                   // 흰색 배경
        elevation: 0,                                                    // 그림자 제거
        automaticallyImplyLeading: false,                                // 뒤로가기 버튼 비활성화
      ),
      // ===== 메인 콘텐츠 영역 =====
      body: Consumer2<AuthProvider, UserProvider>(
        builder: (context, authProvider, userProvider, child) {
          final user = userProvider.currentUser; // 현재 로그인된 사용자 정보
          
          // ===== 로딩 상태 처리 =====
          // 사용자 데이터가 없을 경우 로딩 스피너 표시
          if (user == null) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0), // 전체 16px 패딩
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // ===== 사용자 프로필 카드 =====
                // 아바타, 이메일, 가입일 정보를 표시하는 상단 카드
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0), // 카드 내부 16px 패딩
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // 사용자 아바타 (원형 보라색 배경에 사람 아이콘)
                            CircleAvatar(
                              radius: 30,                            // 60px 지름의 원
                              backgroundColor: Colors.deepPurple,    // 보라색 배경
                              child: Icon(Icons.person, color: Colors.white, size: 30), // 흰색 사람 아이콘
                            ),
                            SizedBox(width: 16), // 아바타와 텍스트 간 16px 간격
                            
                            // 사용자 정보 텍스트 영역
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 사용자 이메일 (없으면 "사용자" 표시)
                                  Text(
                                    user.email.isNotEmpty ? user.email : '사용자',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  // 가입일 (YYYY-MM-DD 형태로 표시)
                                  Text(
                                    '가입일: ${user.createdAt.toString().split(' ')[0]}', // 날짜 부분만 추출
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // ===== 설정 섹션 제목 =====
                Text(
                  '⚙️ 설정',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                
                // ===== 일반 설정 메뉴 항목들 =====

                // 앱 버전 메뉴 (터치해도 아무 동작 없음)
                _buildSettingItem(
                  Icons.info_outline,        // 정보 아이콘
                  '앱 버전',                 // 메뉴 제목
                  '버전 1.0.0',              // 부제목 (현재 앱 버전)
                  () {},                     // 빈 콜백 (터치해도 아무 일 없음)
                ),
                
                // 도움말 메뉴 (현재 기능 없음)
                _buildSettingItem(
                  Icons.help_outline,        // 도움말 아이콘
                  '도움말',                  // 메뉴 제목
                  '사용법 및 FAQ',           // 부제목
                  () {},                     // 빈 콜백 (향후 구현 예정)
                ),
                
                // 이용 약관 및 개인정보 처리방침 메뉴 (웹페이지 연결)
                _buildSettingItem(
                  Icons.privacy_tip_outlined,           // 개인정보 아이콘
                  '이용 약관 및 개인정보 처리방침',      // 메뉴 제목
                  '서비스 이용 약관 및 개인정보 보호', // 부제목
                  () => _openTermsAndPrivacy(),         // 웹페이지 열기
                ),
                
                SizedBox(height: 20),

                // ===== 로그아웃 메뉴 (위험한 작업이므로 빨간색 + 확인 다이얼로그) =====
                _buildSettingItem(
                  Icons.logout,              // 로그아웃 아이콘
                  '로그아웃',                // 메뉴 제목
                  '계정에서 로그아웃',       // 부제목
                  () async {                 // 복잡한 로그아웃 로직
                    // ===== 로그아웃 확인 다이얼로그 표시 =====
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('로그아웃'),
                        content: Text('정말 로그아웃하시겠습니까?'), // 사용자 확인
                        actions: [
                          // 취소 버튼
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('취소'),
                          ),
                          // 로그아웃 확인 버튼
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('로그아웃'),
                          ),
                        ],
                      ),
                    );

                    // ===== 사용자가 로그아웃을 확인했을 경우 실제 로그아웃 실행 =====
                    if (result == true) {
                      await authProvider.signOut();                                // Firebase 로그아웃
                      if (context.mounted) {                                       // 위젯이 여전히 마운트 상태인지 확인
                        Navigator.popUntil(context, (route) => route.isFirst); // 로그인 화면으로 이동
                      }
                    }
                  },
                  color: Colors.red, // 위험한 작업임을 나타내는 빨간색
                ),

                SizedBox(height: 12),

                // ===== 회원 탈퇴 메뉴 (위험한 작업이므로 회색 + 경고 다이얼로그) =====
                _buildSettingItem(
                  Icons.person_remove_outlined,  // 회원 탈퇴 아이콘
                  '회원 탈퇴',                    // 메뉴 제목
                  '계정 및 모든 데이터 삭제',     // 부제목
                  () async {                      // 복잡한 탈퇴 로직
                    // ===== 탈퇴 경고 다이얼로그 표시 =====
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('회원 탈퇴'),
                        content: Text(
                          '정말 탈퇴하시겠습니까?\n\n'
                          '탈퇴 시 모든 데이터가 삭제되며\n'
                          '복구할 수 없습니다.',
                        ),
                        actions: [
                          // 취소 버튼
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('취소'),
                          ),
                          // 탈퇴 확인 버튼 (빨간색)
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text('탈퇴'),
                          ),
                        ],
                      ),
                    );

                    // ===== 사용자가 탈퇴를 확인했을 경우 실제 탈퇴 실행 =====
                    if (result == true && context.mounted) {
                      // 로딩 다이얼로그 표시
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      try {
                        final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
                        if (currentUser == null) {
                          throw Exception('로그인 정보를 찾을 수 없습니다.');
                        }

                        final uid = currentUser.uid;

                        // 1. Firestore 사용자 문서 삭제
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .delete();

                        // 2. Firebase Authentication 계정 삭제
                        await currentUser.delete();

                        // 로딩 다이얼로그 닫기
                        if (context.mounted) {
                          Navigator.pop(context);

                          // 성공 메시지 표시
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('회원 탈퇴가 완료되었습니다.'),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // 로그인 화면으로 이동
                          await Future.delayed(Duration(milliseconds: 500));
                          if (context.mounted) {
                            Navigator.popUntil(context, (route) => route.isFirst);
                          }
                        }
                      } catch (e) {
                        // 로딩 다이얼로그 닫기
                        if (context.mounted) {
                          Navigator.pop(context);

                          // 에러 메시지 표시
                          String errorMessage = '회원 탈퇴 중 오류가 발생했습니다.';

                          // Firebase 에러 타입별 메시지
                          if (e is firebase_auth.FirebaseAuthException) {
                            if (e.code == 'requires-recent-login') {
                              errorMessage = '보안을 위해 다시 로그인 후 탈퇴해주세요.';
                            }
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                        debugPrint('회원 탈퇴 오류: $e');
                      }
                    }
                  },
                  color: Colors.grey[600], // 회색 (로그아웃과 구분)
                ),
                
                SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===== 이용 약관 및 개인정보 처리방침 관련 메서드 =====

  /// 이용 약관 및 개인정보 처리방침 웹페이지를 여는 메서드
  /// Firebase Hosting에 배포된 웹페이지를 브라우저로 엽니다
  Future<void> _openTermsAndPrivacy() async {
    final Uri url = Uri.parse('https://apptech-9928c.web.app/terms_and_privacy.html');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // 외부 브라우저에서 열기
        );
      } else {
        debugPrint('약관 페이지를 열 수 없습니다: $url');
      }
    } catch (e) {
      debugPrint('약관 페이지 열기 오류: $e');
    }
  }

  // ===== 통계 카드 생성 유틸리티 메서드 =====
  
  /// 통계 정보를 표시하는 카드 위젯을 생성하는 메서드
  /// [title]: 카드 하단에 표시될 제목
  /// [value]: 카드 중앙에 크게 표시될 값
  /// [color]: 아이콘과 값에 적용될 테마 색상
  /// [icon]: 카드 상단에 표시될 아이콘
  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0), // 카드 내부 16px 패딩
        child: Column(
          children: [
            // 상단 아이콘 (32px 크기, 테마 색상)
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            
            // 중앙 값 표시 (24px 크기, 굵은 글씨, 테마 색상)
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            
            // 하단 제목 표시 (12px 크기, 회색 텍스트)
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 설정 메뉴 항목 생성 유틸리티 메서드 =====
  
  /// 설정 화면의 메뉴 항목을 생성하는 메서드
  /// [icon]: 왼쪽에 표시될 아이콘
  /// [title]: 메뉴의 주제목
  /// [subtitle]: 메뉴의 부제목/설명
  /// [onTap]: 메뉴 터치 시 실행될 콜백 함수
  /// [color]: 선택적 색상 (기본값: 회색, 위험한 작업 시 빨간색)
  Widget _buildSettingItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? color, // 선택적 색상 매개변수
  }) {
    return Card(
      child: ListTile(
        // 왼쪽 아이콘 (기본: 회색, color 지정 시 해당 색상)
        leading: Icon(icon, color: color ?? Colors.grey[600]),
        
        // 메인 제목 (기본: 검은색, color 지정 시 해당 색상)
        title: Text(
          title,
          style: TextStyle(
            color: color ?? Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        
        // 부제목/설명 (항상 기본 색상)
        subtitle: Text(subtitle),
        
        // 오른쪽 화살표 아이콘 (터치 가능함을 나타냄)
        trailing: Icon(Icons.chevron_right, color: Colors.grey),
        
        // 터치 이벤트 핸들러
        onTap: onTap,
      ),
    );
  }
}