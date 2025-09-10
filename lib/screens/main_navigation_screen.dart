import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import 'keyboard_screen.dart';
import 'profile_screen.dart';
import 'store_screen.dart';

/// AppTech 메인 네비게이션 화면
/// 하단 탭 네비게이션을 통해 홈, 키보드, 상점, 마이페이지 간 이동을 제공하는 메인 컨테이너 화면
/// IndexedStack을 사용하여 화면 전환 시 상태를 유지하고 부드러운 탭 전환 경험 제공
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  
  // ===== 네비게이션 상태 변수 =====
  
  /// 현재 선택된 탭 인덱스 (0: 홈, 1: 키보드, 2: 상점, 3: 마이페이지)
  int _selectedIndex = 0;

  // ===== 생명주기 메서드 =====
  
  /// 위젯 초기화 시 호출되는 메서드
  /// 프레임 렌더링 완료 후 사용자 데이터를 로드하여 화면 깜빡임 방지
  @override
  void initState() {
    super.initState();
    // 프레임 렌더링 완료 후 실행하여 BuildContext 안전 보장
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // 인증된 사용자만 데이터 로드 (로그인 상태 및 사용자 정보 존재 확인)
      if (authProvider.isAuthenticated && authProvider.user != null) {
        userProvider.loadUserData(authProvider.user!.uid); // Firebase UID로 사용자 데이터 로드
      }
    });
  }

  // ===== 탭 네비게이션 이벤트 핸들러 =====
  
  /// 하단 네비게이션 바 탭 클릭 시 호출되는 메서드
  /// [index]: 선택된 탭의 인덱스 (0: 홈, 1: 키보드, 2: 상점, 3: 마이페이지)
  /// setState를 통해 화면을 다시 그려 선택된 탭을 변경
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;  // 선택된 탭 인덱스 업데이트
    });
  }

  // ===== 메인 UI 빌드 메서드 =====
  
  /// 메인 네비게이션 화면의 UI를 구성하는 메인 빌드 메서드
  /// IndexedStack으로 모든 화면을 유지하여 탭 전환 시 상태 보존
  /// 하단 네비게이션 바로 4개 탭 간 전환 제공
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ===== 메인 콘텐츠 영역 (IndexedStack으로 화면 전환) =====
      body: IndexedStack(
        index: _selectedIndex,            // 현재 선택된 탭에 해당하는 화면 표시
        children: const [
          HomeContent(),                  // 0: 홈 화면 (캐시 트래킹 및 광고)
          KeyboardContent(),              // 1: 키보드 화면 (타이핑 연습)
          StoreContent(),                 // 2: 상점 화면 (기프티콘 구매)
          ProfileContent(),               // 3: 마이페이지 (사용자 정보 및 설정)
        ],
      ),
      
      // ===== 하단 네비게이션 바 =====
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,         // 현재 선택된 탭 강조 표시
        selectedItemColor: Colors.black,      // 선택된 탭 아이콘 색상 (검은색)
        unselectedItemColor: Colors.grey,     // 선택되지 않은 탭 아이콘 색상 (회색)
        type: BottomNavigationBarType.fixed,  // 4개 탭을 고정 크기로 균등 배치
        onTap: _onItemTapped,                 // 탭 클릭 이벤트 핸들러 연결
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),           // 홈 탭
          BottomNavigationBarItem(icon: Icon(Icons.keyboard), label: '키보드'),    // 키보드 탭
          BottomNavigationBarItem(icon: Icon(Icons.store), label: '상점'),        // 상점 탭
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'), // 마이페이지 탭
        ],
      ),
    );
  }
}

// ===== 홈 콘텐츠 위젯 (메인 캐시 트래킹 화면) =====

/// AppTech 홈 화면 콘텐츠
/// 사용자의 일일 캐시 획득 현황을 원형 진행률로 표시하고
/// 캐시 수집, 광고 시청, 보너스 상자 등의 기능을 제공하는 메인 화면
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with TickerProviderStateMixin {
  
  // ===== 애니메이션 컨트롤러 =====
  
  /// 코인 탭 시 스케일 애니메이션을 위한 컨트롤러
  late AnimationController _scaleController;
  
  /// 코인 아이콘 크기 변화 애니메이션 (1.0 → 0.9 → 1.0)
  late Animation<double> _scaleAnimation;

  // ===== 애니메이션 초기화 =====
  
  /// 위젯 초기화 시 애니메이션 컨트롤러와 애니메이션 설정
  @override
  void initState() {
    super.initState();
    // 코인 탭 애니메이션 컨트롤러 초기화 (150ms 지속)
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),  // 애니메이션 지속 시간
      vsync: this,                                   // TickerProvider로 애니메이션 최적화
    );
    // 스케일 애니메이션 정의 (원래 크기 → 90% 축소)
    _scaleAnimation = Tween<double>(
      begin: 1.0,     // 시작 크기 (100%)
      end: 0.9,       // 끝 크기 (90%)
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,  // 부드러운 in-out 커브
    ));
  }

  // ===== 리소스 정리 =====
  
  /// 위젯 제거 시 애니메이션 컨트롤러 리소스 해제
  @override
  void dispose() {
    _scaleController.dispose();  // 메모리 누수 방지를 위한 컨트롤러 해제
    super.dispose();
  }

  // ===== 코인 탭 이벤트 핸들러 =====
  
  /// 코인 아이콘 탭 시 호출되는 메서드
  /// [userProvider]: 사용자 데이터 관리 프로바이더
  /// [readyCash]: 수집 가능한 캐시 양
  /// 수집 가능한 캐시가 있을 때만 애니메이션과 함께 캐시 수집
  void _onCoinTap(UserProvider userProvider, int readyCash) {
    if (readyCash > 0) {                          // 수집 가능한 캐시가 있는 경우에만
      _scaleController.forward().then((_) {       // 축소 애니메이션 실행
        _scaleController.reverse();               // 애니메이션 완료 후 원래 크기로 복구
      });
      // 캐시 수집 메서드 호출 (UserProvider를 통해 상태 업데이트)
      userProvider.collectCash();
    }
  }

  // ===== 메인 UI 빌드 메서드 =====
  
  /// 홈 화면 UI를 구성하는 메인 빌드 메서드
  /// UserProvider로 사용자 상태를 감시하며 실시간 데이터 업데이트
  /// 원형 진행률, 코인 애니메이션, 광고 영역, 보너스 상자를 포함
  @override
  Widget build(BuildContext context) {
    // ===== 상수 및 설정값 =====
    final int maxCashPerDay = 100;  // 일일 최대 캐시 획득량 (100캐시)

    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // ===== 로딩 상태 처리 =====
        // 사용자 데이터 로딩 중이거나 사용자 정보가 없을 경우 로딩 표시
        if (userProvider.isLoading || userProvider.currentUser == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // ===== 캐시 계산 로직 =====
        final user = userProvider.currentUser!;
        final currentCash = user.todayCharCount ~/ 10;                      // 현재 획득 가능 캐시 (10자당 1캐시)
        final double progress = currentCash / maxCashPerDay;                 // 일일 목표 대비 진행률 (0.0-1.0)
        final int readyCash = (user.todayCharCount ~/ 10) - user.collectedCash; // 수집 대기 중인 캐시

        return Scaffold(
          backgroundColor: Colors.white,        // 전체 배경색: 흰색
          
          // ===== 상단 앱바 =====
          appBar: AppBar(
            backgroundColor: Colors.white,      // 앱바 배경색: 흰색
            elevation: 0,                       // 그림자 제거
            automaticallyImplyLeading: false,   // 자동 뒤로가기 버튼 비활성화
            
            // 좌측 앱 사용법 버튼
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ElevatedButton(
                onPressed: () {},               // TODO: 사용법 화면으로 이동 구현
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,   // 검은색 버튼
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: const Text("앱 사용법", style: TextStyle(fontSize: 12)),
              ),
            ),
            
            // 우측 액션 버튼들
            actions: [
              // 채팅/문의 버튼
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                onPressed: () {},               // TODO: 문의 화면으로 이동 구현
              ),
              // 총 보유 캐시 표시 칩
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  avatar: const Icon(Icons.monetization_on, color: Colors.amber, size: 18), // 황금색 코인 아이콘
                  label: Text('${user.totalCash} 캐시', style: const TextStyle(color: Colors.black)),
                  backgroundColor: Colors.grey.shade200,  // 연한 회색 배경
                ),
              )
            ],
          ),
          // ===== 메인 콘텐츠 영역 =====
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                
                // ===== 원형 진행률 표시기 스택 =====
                // 중앙에 타이핑 글자수와 코인, 외곽에 진행률 원형 바
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 원형 진행률 바 (일일 캐시 목표 대비 진행률)
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: progress,                                              // 진행률 (0.0-1.0)
                        strokeWidth: 16,                                              // 진행률 바 두께
                        backgroundColor: Colors.grey.shade300,                       // 배경 원형 색상 (연한 회색)
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.black), // 진행률 색상 (검은색)
                      ),
                    ),
                    
                    // 중앙 텍스트 정보 (오늘 타이핑 글자수)
                    Column(
                      children: [
                        Text('${user.todayCharCount}자', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), // 타이핑한 글자수
                        const Text('10자당 1캐시 저장', style: TextStyle(fontSize: 14, color: Colors.grey)),                 // 캐시 적립 규칙 안내
                      ],
                    ),
                    // 하단 코인 수집 버튼 (애니메이션 포함)
                    Positioned(
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _onCoinTap(userProvider, readyCash),  // 코인 탭 이벤트
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,               // 애니메이션 스케일 적용
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  // 메인 코인 아이콘
                                  Icon(
                                    Icons.monetization_on,
                                    size: 40,
                                    color: readyCash > 0 ? Colors.amber : Colors.grey, // 수집 가능 시 황금색, 불가능 시 회색
                                  ),
                                  // 수집 가능한 캐시 개수 표시 배지
                                  CircleAvatar(
                                    radius: 8,
                                    backgroundColor: Colors.red,           // 빨간색 배지
                                    child: Text(
                                      '$readyCash',                       // 수집 대기 중인 캐시 개수
                                      style: const TextStyle(fontSize: 10, color: Colors.white),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                
                // ===== 일일 목표 달성 알림 메시지 =====
                Text(
                  '❗ 오늘 $maxCashPerDay캐시 모두 적립했습니다 ❗',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // ===== 광고 영역 =====
                // 중간 크기 직사각형 광고 배너 영역 (향후 AdMob 연동 예정)
                Container(
                  width: double.infinity,                          // 전체 너비
                  height: 220,                                     // 광고 높이
                  margin: const EdgeInsets.symmetric(horizontal: 16), // 좌우 16px 마진
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),       // 둥근 모서리
                    border: Border.all(color: Colors.black),       // 검은색 테두리
                  ),
                  child: const Center(child: Text('광고 자리')),   // 임시 텍스트 (향후 광고로 교체)
                ),
                const SizedBox(height: 16),
                // ===== 캐시 보너스 상자 가로 스크롤 영역 =====
                // 추가 캐시를 획득할 수 있는 보너스 상자들을 가로 스크롤로 표시
                SizedBox(
                  height: 150,                                    // 상자 리스트 높이
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,             // 가로 스크롤
                    itemCount: 5,                                 // 보너스 상자 5개
                    itemBuilder: (_, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0), // 상자 간 8px 간격
                        child: Container(
                          width: 120,                             // 각 상자 너비
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12), // 둥근 모서리
                            color: Colors.grey.shade100,          // 연한 회색 배경
                            border: Border.all(color: Colors.black), // 검은색 테두리
                          ),
                          child: Center(child: Text('캐시 상자 $index')), // 임시 텍스트 (향후 실제 보너스 상자로 교체)
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20), // 하단 여백 추가 (네비게이션 바와의 간격 확보)
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===== 네비게이션 탭 콘텐츠 래퍼 위젯들 =====
// 각 탭에 해당하는 실제 화면을 감싸는 래퍼 위젯들
// IndexedStack에서 사용되어 화면 전환 시 상태 유지

/// 키보드 탭 콘텐츠 래퍼
/// KeyboardScreen을 감싸서 탭 네비게이션에서 사용
class KeyboardContent extends StatelessWidget {
  const KeyboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const KeyboardScreen();  // 실제 키보드 화면으로 위임
  }
}

/// 상점 탭 콘텐츠 래퍼
/// StoreScreen을 감싸서 탭 네비게이션에서 사용
class StoreContent extends StatelessWidget {
  const StoreContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const StoreScreen();     // 실제 상점 화면으로 위임
  }
}

/// 마이페이지 탭 콘텐츠 래퍼
/// ProfileScreen을 감싸서 탭 네비게이션에서 사용
class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfileScreen();   // 실제 프로필 화면으로 위임
  }
}