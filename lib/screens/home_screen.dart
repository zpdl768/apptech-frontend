import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../services/reward_ad_service.dart';
import 'keyboard_screen.dart';
import 'store_screen.dart';
import 'profile_screen.dart';

/// AppTech 메인 홈 화면
/// 사용자의 타이핑 진행률, 캐시 수집, 광고, 캐시 상자 등을 표시하는 메인 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// HomeScreen의 상태 관리 클래스
/// SingleTickerProviderStateMixin: 코인 애니메이션을 위한 AnimationController 사용
class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  
  // ===== 상수 및 설정값 =====
  
  /// 하루 최대 캐시 적립 한도 (10자당 1캐시, 최대 100캐시)
  final int maxCashPerDay = 100;
  
  /// 현재 선택된 하단 탭 인덱스 (0: 홈, 1: 키보드, 2: 상점, 3: 마이페이지)
  int _selectedIndex = 0;
  
  // ===== Google AdMob 관련 변수 =====
  
  /// Google AdMob 배너 광고 인스턴스
  BannerAd? _bannerAd;
  
  /// 배너 광고 로딩 완료 여부
  bool _isBannerAdReady = false;
  
  /// 리워드 광고 서비스 인스턴스
  final RewardAdService _rewardAdService = RewardAdService();
  
  // ===== 코인 터치 애니메이션 관련 변수 =====
  
  /// 코인 애니메이션 컨트롤러 (200ms 지속시간)
  late AnimationController _coinAnimationController;
  
  /// 코인이 위로 올라갔다 내려오는 애니메이션 (-15px 이동)
  late Animation<double> _coinAnimation;

  // ===== 하단 탭 네비게이션 관련 메서드 =====
  
  /// 하단 탭이 선택되었을 때 호출되는 메서드
  /// [index]: 선택된 탭의 인덱스 (0: 홈, 1: 키보드, 2: 상점, 3: 마이페이지)
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// 현재 선택된 탭에 따라 해당하는 화면 위젯을 반환
  /// 기본값은 홈 화면 콘텐츠
  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent(); // 홈 화면
      case 1:
        return KeyboardScreen();    // 타이핑 키보드 화면
      case 2:
        return StoreScreen();       // 상점 화면
      case 3:
        return ProfileScreen();     // 마이페이지 화면
      default:
        return _buildHomeContent();
    }
  }

  // ===== Google AdMob 광고 관련 메서드 =====
  
  /// Google AdMob 배너 광고를 로드하는 메서드
  /// mediumRectangle 사이즈 (300x250px) 테스트 광고 사용
  void _loadBannerAd() {
    _bannerAd = BannerAd(
      // 테스트용 광고 ID (실제 배포 시 실제 광고 ID로 교체 필요)
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      request: const AdRequest(),
      size: AdSize.mediumRectangle, // 300x250 픽셀 크기의 중간 직사각형 광고
      listener: BannerAdListener(
        // 광고 로딩 성공 시
        onAdLoaded: (Ad ad) {
          debugPrint('Banner Ad loaded.');
          setState(() {
            _isBannerAdReady = true; // 광고 표시 준비 완료
          });
        },
        // 광고 로딩 실패 시
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('Banner Ad failed to load: $error');
          ad.dispose();
          setState(() {
            _isBannerAdReady = false; // 광고 표시 불가 상태
          });
        },
      ),
    );
    _bannerAd?.load(); // 광고 로딩 시작
  }

  // ===== 캐시 수집 및 애니메이션 관련 메서드 =====
  
  /// 코인을 터치했을 때 캐시 수집과 애니메이션을 동시에 실행하는 메서드
  /// 복잡한 로직: readyCash 계산, UserProvider 호출, 애니메이션 실행
  void _animateAndCollectCash() {
    // UserProvider에서 현재 사용자 정보 가져오기
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.currentUser;
    if (user == null) return; // 사용자 정보가 없으면 종료
    
    // 복잡한 캐시 계산 로직
    // readyCash = (오늘 타이핑한 글자수 ÷ 10) - 이미 수집한 캐시
    // 최소 0, 최대 하루 한도(100)로 제한
    final readyCash = ((user.todayCharCount ~/ 10) - user.collectedCash).clamp(0, maxCashPerDay);
    if (readyCash <= 0) return; // 수집할 캐시가 없으면 종료
    
    // 캐시 수집 실행 (UserProvider를 통해 Firestore에 저장)
    userProvider.collectCash();
    
    // 코인 터치 애니메이션 실행
    // 200ms 동안 -15px 위로 올라간 후 다시 원래 위치로 돌아오기
    _coinAnimationController.forward().then((_) {
      _coinAnimationController.reverse();
    });
  }

  // ===== 생명주기 관리 메서드 =====
  
  /// 위젯 해제 시 리소스 정리
  /// 메모리 누수 방지를 위해 애니메이션 컨트롤러와 광고 인스턴스 해제
  @override
  void dispose() {
    _coinAnimationController.dispose(); // 애니메이션 컨트롤러 해제
    _bannerAd?.dispose();               // 배너 광고 인스턴스 해제
    _rewardAdService.dispose();         // 리워드 광고 서비스 해제
    super.dispose();
  }

  // ===== 캐시 상자 UI 관련 유틸리티 메서드 =====
  
  /// 상자 상태별 배경색을 반환하는 메서드
  Color _getBoxBackgroundColor(BoxState state) {
    switch (state) {
      case BoxState.locked:
        return Colors.grey.shade100;      // 잠긴 상태: 연한 회색
      case BoxState.available:
        return Colors.amber.shade50;      // 사용 가능: 연한 황금색 (빛나는 효과)
      case BoxState.completed:
        return Colors.green.shade50;      // 완료: 연한 초록색
    }
  }
  
  /// 상자 상태별 테두리색을 반환하는 메서드
  Color _getBoxBorderColor(BoxState state) {
    switch (state) {
      case BoxState.locked:
        return Colors.grey.shade300;      // 잠긴 상태: 회색 테두리
      case BoxState.available:
        return Colors.amber.shade400;     // 사용 가능: 황금색 테두리
      case BoxState.completed:
        return Colors.green.shade400;     // 완료: 초록색 테두리
    }
  }
  
  /// 상자 상태별 아이콘 색상을 반환하는 메서드
  Color _getBoxIconColor(BoxState state) {
    switch (state) {
      case BoxState.locked:
        return Colors.grey.shade400;      // 잠긴 상태: 회색
      case BoxState.available:
        return Colors.amber.shade700;     // 사용 가능: 진한 황금색
      case BoxState.completed:
        return Colors.green.shade600;     // 완료: 진한 초록색
    }
  }
  
  /// 상자 상태별 텍스트 색상을 반환하는 메서드
  Color _getBoxTextColor(BoxState state) {
    switch (state) {
      case BoxState.locked:
        return Colors.grey.shade600;      // 잠긴 상태: 회색
      case BoxState.available:
        return Colors.amber.shade800;     // 사용 가능: 진한 황금색
      case BoxState.completed:
        return Colors.green.shade700;     // 완료: 진한 초록색
    }
  }
  
  /// 상자 인덱스와 상태에 따라 적절한 아이콘을 반환하는 메서드
  IconData _getBoxIcon(int index, BoxState state) {
    if (state == BoxState.completed) {
      return Icons.check_circle; // 완료된 상자는 체크 아이콘
    }
    
    // 10번째 상자(index 9)는 저금통, 나머지는 모두 코인
    if (index == 9) {
      return Icons.savings; // 10번째 상자: 저금통
    } else {
      return Icons.monetization_on; // 1~9번째 상자: 코인
    }
  }
  
  /// 상자 상태와 필요 글자수에 따른 텍스트를 반환하는 메서드
  String _getBoxText(BoxState state, int requiredChars) {
    switch (state) {
      case BoxState.locked:
        return '$requiredChars자\n필요'; // 잠긴 상태: 필요한 글자수 표시
      case BoxState.available:
        return '광고 시청\n가능!';        // 사용 가능: 광고 시청 안내
      case BoxState.completed:
        return '수집 완료';              // 완료: 수집 완료 표시
    }
  }
  
  /// 캐시 상자가 탭되었을 때 호출되는 메서드
  void _onRewardBoxTapped(int index, BoxState state) {
    switch (state) {
      case BoxState.locked:
        // 잠긴 상자: 필요한 글자수 안내 스낵바 표시
        final requiredChars = (index + 1) * 100;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$requiredChars자를 입력하면 이 상자가 활성화됩니다!'),
            backgroundColor: Colors.grey.shade600,
            duration: Duration(seconds: 2),
          ),
        );
        break;
        
      case BoxState.available:
        // 활성화된 상자: 리워드 광고 시청 (향후 AdMob 구현)
        _showRewardAd(index);
        break;
        
      case BoxState.completed:
        // 완료된 상자: 완료 상태 안내 스낵바 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미 수집 완료한 상자입니다!'),
            backgroundColor: Colors.green.shade600,
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }
  
  /// 리워드 광고를 표시하는 메서드
  Future<void> _showRewardAd(int boxIndex) async {
    // 광고가 준비되지 않은 경우 로딩 시도
    if (!_rewardAdService.isReady) {
      if (!_rewardAdService.isLoading) {
        // 광고 로딩 시작
        _showLoadingDialog('광고를 준비 중입니다...');
        
        await _rewardAdService.loadRewardedAd(
          onAdLoaded: () {
            // 로딩 완료 시 다이얼로그 닫기
            if (mounted) Navigator.pop(context);
            // 광고 표시
            _displayRewardAd(boxIndex);
          },
          onAdFailedToLoad: (error) {
            // 로딩 실패 시
            if (mounted) {
              Navigator.pop(context); // 로딩 다이얼로그 닫기
              _showErrorDialog('광고 로딩 실패', '잠시 후 다시 시도해주세요.\n\n$error');
            }
          },
        );
      } else {
        // 이미 로딩 중인 경우
        _showErrorDialog('광고 준비 중', '광고를 준비 중입니다. 잠시 후 다시 시도해주세요.');
      }
      return;
    }
    
    // 광고가 준비된 경우 바로 표시
    await _displayRewardAd(boxIndex);
  }
  
  /// 실제 리워드 광고를 표시하는 메서드
  Future<void> _displayRewardAd(int boxIndex) async {
    final success = await _rewardAdService.showRewardedAd(
      onUserEarnedReward: (rewardAmount) async {
        // 광고 시청 완료 시 캐시 지급
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final actualReward = await userProvider.completeRewardAd(boxIndex);
        
        if (actualReward > 0 && mounted) {
          // 성공적으로 캐시를 받은 경우
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 축하합니다! $actualReward 캐시를 획득했습니다!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
              action: SnackBarAction(
                label: '확인',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      },
      onAdFailedToShow: (error) {
        if (mounted) {
          _showErrorDialog('광고 표시 실패', '광고를 표시할 수 없습니다.\n\n$error');
        }
      },
    );
    
    if (!success) {
      // 광고 표시 실패
      if (mounted) {
        _showErrorDialog('광고 오류', '광고를 표시할 수 없습니다. 잠시 후 다시 시도해주세요.');
      }
    }
  }
  
  /// 로딩 다이얼로그를 표시하는 메서드
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
  
  /// 에러 다이얼로그를 표시하는 메서드
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  // ===== UI 구성 메서드 =====
  
  /// 홈 화면의 메인 콘텐츠를 구성하는 메서드
  /// 포함 요소: 타이핑 진행률 원형 그래프, 광고, 캐시 상자들
  Widget _buildHomeContent() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser!;
        
        // 에러 상태 체크 및 SnackBar 표시
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (userProvider.lastError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userProvider.lastError!),
                backgroundColor: userProvider.isDailyLimitReached 
                  ? Colors.orange.shade700 
                  : Colors.red.shade700,
                duration: Duration(seconds: 4),
                action: SnackBarAction(
                  label: '확인',
                  textColor: Colors.white,
                  onPressed: () {
                    userProvider.clearError();
                  },
                ),
              ),
            );
            userProvider.clearError();
          }
        });
        
        // 복잡한 캐시 관련 계산들
        final currentCash = (user.todayCharCount ~/ 10).clamp(0, maxCashPerDay);           // 현재 적립된 캐시 (최대 100)
        final readyCash = ((user.todayCharCount ~/ 10) - user.collectedCash).clamp(0, maxCashPerDay); // 수집 가능한 캐시
        final double progress = (user.todayCharCount / 1000).clamp(0.0, 1.0);             // 진행률 (1000자 기준)

        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 24),
              
              // ===== 메인 섹션: 타이핑 진행률 원형 그래프 =====
              Material(
                color: Colors.transparent,
                child: InkWell(
                  // 터치 가능 조건: 수집할 캐시가 있을 때만
                  onTap: readyCash > 0 ? _animateAndCollectCash : null,
                  borderRadius: BorderRadius.circular(100),
                  // 터치 효과 (보라색 물결 효과)
                  splashColor: readyCash > 0 ? Colors.deepPurple.withValues(alpha: 0.1) : Colors.transparent,
                  highlightColor: readyCash > 0 ? Colors.deepPurple.withValues(alpha: 0.05) : Colors.transparent,
                  child: Container(
                    width: 220,  // 전체 컨테이너 크기
                    height: 220,
                    padding: EdgeInsets.all(10),
                    child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 원형 진행률 표시기 (200x200 크기)
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: progress,                               // 진행률 (0.0 ~ 1.0)
                          strokeWidth: 16,                               // 선 두께
                          backgroundColor: Colors.grey.shade300,         // 배경 색상 (회색)
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black), // 진행 색상 (검은색)
                        ),
                      ),
                      
                      // 중앙 텍스트 정보 (글자수, 설명, 안내 메시지)
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text('${user.todayCharCount}자', 
                              style: TextStyle(
                                fontSize: 28, 
                                fontWeight: FontWeight.bold,
                                color: Colors.black
                              )),
                          Text('10자당 1캐시 저장', 
                              style: TextStyle(
                                fontSize: 14, 
                                color: Colors.grey[600]
                              )),
                          if (readyCash > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('터치하여 캐시 수집!', 
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.w600
                                  )),
                            ),
                        ],
                      ),
                      // ===== 코인 터치 애니메이션 섹션 =====
                      // 하단에 위치한 코인 아이콘, 터치 시 -15px 위로 올라가는 애니메이션 실행
                      Positioned(
                        bottom: 10, // 원형 그래프 하단에서 10px 위쪽에 위치
                        child: GestureDetector(
                          // 수집할 캐시가 있을 때만 터치 가능
                          onTap: readyCash > 0 ? _animateAndCollectCash : null,
                          child: AnimatedBuilder(
                            animation: _coinAnimation, // 200ms, Curves.bounceOut 애니메이션
                            builder: (context, child) {
                              return Transform.translate(
                                // Y축 이동: 0px에서 -15px로 위로 올라갔다가 다시 내려옴
                                offset: Offset(0, _coinAnimation.value),
                                child: Stack(
                                  alignment: Alignment.topRight, // 알림 배지가 코인 우상단에 위치
                                  children: [
                                    // 메인 코인 아이콘 (40px 크기)
                                    Icon(Icons.monetization_on, 
                                        size: 40,
                                        color: readyCash > 0 
                                            ? Colors.amber.shade600  // 수집 가능: 황금색
                                            : Colors.grey.shade400), // 수집 불가: 회색
                                    // 수집 가능한 캐시 수량 알림 배지 (빨간 원)
                                    if (readyCash > 0)
                                      CircleAvatar(
                                        radius: 8,               // 16px 지름의 작은 원
                                        backgroundColor: Colors.red,
                                        child: Text('$readyCash', // 수집 가능한 캐시 숫자 표시
                                            style: TextStyle(fontSize: 10, color: Colors.white)),
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
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // ===== 타이핑 캐시 경고 메시지 (기존 100캐시 한도) =====
              // 하루 최대 타이핑 캐시(100캐시) 달성 시에만 표시되는 경고 메시지
              if (currentCash >= maxCashPerDay)
                Text(
                  '📝 오늘 타이핑으로 $maxCashPerDay캐시 모두 적립했습니다',
                  style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
                ),
              SizedBox(height: 16),
              
              // ===== Google AdMob 배너 광고 섹션 =====
              // mediumRectangle 사이즈 (300x250px) 광고 또는 로딩 플레이스홀더
              Container(
                width: double.infinity,     // 화면 전체 너비
                height: 250,                // mediumRectangle 표준 높이
                margin: EdgeInsets.symmetric(horizontal: 16), // 좌우 16px 여백
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),    // 둥근 모서리
                  border: Border.all(color: Colors.grey.shade300), // 연한 회색 테두리
                  color: Colors.grey.shade50,                 // 연한 회색 배경
                ),
              child: _isBannerAdReady && _bannerAd != null
                    ? // 광고 로딩 완료 시: 실제 AdMob 배너 광고 표시
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16), // 컨테이너와 동일한 둥근 모서리
                        child: AdWidget(ad: _bannerAd!),         // Google AdMob 위젯
                      )
                    : // 광고 로딩 중 또는 실패 시: 플레이스홀더 표시
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.ads_click, 
                                color: Colors.grey.shade400, size: 32), // 광고 아이콘
                            SizedBox(height: 8),
                            Text('광고 로딩 중...', 
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                )),
                          ],
                        ),
                      ),
              ),
              SizedBox(height: 16),
              
              // ===== 수평 스크롤 캐시 상자들 섹션 =====
              // 리워드 광고를 통한 추가 캐시 획득 방법들을 표시하는 수평 스크롤 리스트
              SizedBox(
                height: 90, // 고정 높이 90px
                child: ListView.builder(
                  scrollDirection: Axis.horizontal, // 수평 스크롤
                  itemCount: 10,                   // 총 10개의 캐시 상자
                  itemBuilder: (_, index) {
                    // 상자 활성화에 필요한 글자수 계산 (100, 200, 300, ..., 1000)
                    final requiredChars = (index + 1) * 100;
                    final boxState = user.getBoxState(index);
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0), // 상자간 16px 간격
                      child: GestureDetector(
                        onTap: () => _onRewardBoxTapped(index, boxState),
                        child: Container(
                          width: 105, // 각 상자의 고정 너비
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12), // 둥근 모서리
                            color: _getBoxBackgroundColor(boxState), // 상태별 배경색
                            border: Border.all(color: _getBoxBorderColor(boxState), width: 2), // 상태별 테두리색
                            boxShadow: boxState == BoxState.available ? [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ] : null, // 활성화된 상자만 그림자 효과
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 상태별 아이콘 표시
                              Icon(
                                _getBoxIcon(index, boxState),
                                size: 32,
                                color: _getBoxIconColor(boxState),
                              ),
                              SizedBox(height: 6),
                              // 상태별 텍스트 표시
                              Text(
                                _getBoxText(boxState, requiredChars),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getBoxTextColor(boxState),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
 

  // ===== 위젯 초기화 생명주기 메서드 =====
  
  /// 위젯 생성 시 한 번만 실행되는 초기화 메서드
  /// 애니메이션, 광고, 사용자 데이터를 초기화
  @override
  void initState() {
    super.initState();
    
    // ===== 코인 터치 애니메이션 설정 =====
    // 200ms 지속시간, bounceOut 곡선으로 자연스러운 바운스 효과
    _coinAnimationController = AnimationController(
      duration: Duration(milliseconds: 200), // 애니메이션 지속시간
      vsync: this, // SingleTickerProviderStateMixin 제공
    );
    _coinAnimation = Tween<double>(
      begin: 0.0,   // 시작 위치 (원래 위치)
      end: -15.0,   // 끝 위치 (-15px 위로 이동)
    ).animate(CurvedAnimation(
      parent: _coinAnimationController,
      curve: Curves.bounceOut, // 바운스 효과로 자연스러운 움직임
    ));
    
    // ===== Google AdMob 광고 로딩 시작 =====
    _loadBannerAd();
    
    // ===== 리워드 광고 미리 로딩 (1개만) =====
    // 사용자가 상자를 터치했을 때 즉시 광고를 표시할 수 있도록 미리 1개 로딩
    _rewardAdService.loadRewardedAd(
      onAdLoaded: () => debugPrint('리워드 광고: 초기 로딩 완료'),
      onAdFailedToLoad: (error) => debugPrint('리워드 광고: 초기 로딩 실패 - $error'),
    );
    
    // ===== 위젯 빌드 완료 후 사용자 데이터 로드 =====
    // 화면 렌더링이 완료된 후 비동기적으로 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Firebase Auth에서 로그인된 사용자 확인 후 Firestore 데이터 로드
      if (authProvider.user != null) {
        userProvider.loadUserData(authProvider.user!.uid);
      }
    });
  }

  // ===== 메인 UI 빌드 메서드 =====
  
  /// 화면을 구성하는 메인 빌드 메서드
  /// UserProvider를 통해 사용자 상태를 감시하고 UI를 동적으로 구성
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        // ===== 로딩 상태 처리 =====
        // 사용자 데이터 로딩 중이거나 사용자 정보가 없을 때 로딩 화면 표시
        if (userProvider.isLoading || userProvider.currentUser == null) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()), // 중앙에 로딩 스피너
          );
        }
        
        final user = userProvider.currentUser!; // 현재 로그인된 사용자 정보

        // ===== 메인 Scaffold 구조 =====
        return Scaffold(
          backgroundColor: Colors.white, // 전체 배경색: 흰색
          
          // ===== 상단 앱바 (앱 사용법 버튼 + 총 캐시 표시) =====
          appBar: AppBar(
            backgroundColor: Colors.transparent,    // 투명 배경
            surfaceTintColor: Colors.transparent,   // 머티리얼 틴트 제거
            scrolledUnderElevation: 0,              // 스크롤 시 그림자 제거
            elevation: 0,                           // 기본 그림자 제거
            toolbarHeight: 32,                      // 앱바 높이: 32px
            leadingWidth: 120,                      // leading 영역 너비
            leading: Padding(
              padding: EdgeInsets.only(left: 16),
              child: ElevatedButton(
                onPressed: () => _showAppGuideDialog(context), // 앱 사용법 다이얼로그 표시
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,         // 보라색 배경
                  foregroundColor: Colors.white,              // 흰색 텍스트
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  fixedSize: Size(60, 20),                   // 60x20 고정 크기
                ),
                child: Text(
                  "앱 사용법", 
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            actions: [
              // 채팅 아이콘 (현재 기능 없음)
              IconButton(
                icon: Icon(Icons.chat_bubble_outline, color: Colors.black),
                onPressed: () {}, // 향후 채팅 기능 구현 예정
              ),
              // 총 보유 캐시 표시 컨테이너
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: 116,  // 고정 너비
                  height: 32,  // 고정 높이
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,           // 연한 회색 배경
                    borderRadius: BorderRadius.circular(16), // 둥근 모서리
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 8),
                      Icon(Icons.monetization_on, color: Colors.amber, size: 18), // 코인 아이콘
                      SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          '${user.totalCash} 캐시', // 사용자의 총 보유 캐시
                          style: TextStyle(color: Colors.black, fontSize: 14),
                          textAlign: TextAlign.left,
                          overflow: TextOverflow.ellipsis, // 긴 숫자 시 말줄임 처리
                        ),
                      ),
                      SizedBox(width: 4),
                    ],
                  ),
                ),
              )
            ],
          ),
          
          // ===== 메인 콘텐츠 영역 (선택된 탭에 따라 다른 화면 표시) =====
          body: _getSelectedScreen(), // 현재 선택된 탭의 화면을 표시
          
          // ===== 하단 네비게이션 바 (4개 탭: 홈/키보드/상점/마이페이지) =====
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,              // 현재 선택된 탭 인덱스
            selectedItemColor: Colors.black,           // 선택된 탭 색상: 검은색
            unselectedItemColor: Colors.grey,          // 선택되지 않은 탭 색상: 회색
            backgroundColor: Colors.deepPurple.shade50, // 하단바 배경: 연한 보라색
            type: BottomNavigationBarType.fixed,       // 고정 타입 (4개 탭 모두 표시)
            onTap: _onItemTapped,                      // 탭 선택 시 콜백 함수
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),           // 0: 홈 탭
              BottomNavigationBarItem(icon: Icon(Icons.keyboard), label: '키보드'),    // 1: 키보드 탭  
              BottomNavigationBarItem(icon: Icon(Icons.store), label: '상점'),        // 2: 상점 탭
              BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'), // 3: 마이페이지 탭
            ],
          ),
        );
      },
    );
  }

  // ===== 앱 사용법 다이얼로그 관련 메서드 =====
  
  /// 앱 사용법 다이얼로그를 표시하는 메서드
  /// 블러 배경 효과와 페이드 애니메이션을 적용한 모달 다이얼로그
  void _showAppGuideDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,          // 다이얼로그 외부 터치로 닫기 비활성화
      barrierColor: Colors.black54,       // 어두운 반투명 배경
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: const AppGuideDialog(), // 커스텀 앱 가이드 다이얼로그 위젯
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // 배경 블러 효과 (5px)
          child: FadeTransition(
            opacity: animation,                            // 페이드 인/아웃 애니메이션
            child: child,
          ),
        );
      },
    );
  }
}

// ===== 앱 사용법 다이얼로그 위젯 클래스 =====

/// 앱 사용법을 설명하는 다중 페이지 다이얼로그 위젯
/// 5개 페이지로 구성된 가이드를 좌우 네비게이션으로 탐색 가능
class AppGuideDialog extends StatefulWidget {
  const AppGuideDialog({super.key});
  
  @override
  State<AppGuideDialog> createState() => _AppGuideDialogState();
}

/// AppGuideDialog의 상태 관리 클래스
/// 5개 페이지간 네비게이션과 컨텐츠 관리를 담당
class _AppGuideDialogState extends State<AppGuideDialog> {
  
  // ===== 페이지 네비게이션 상태 변수 =====
  
  /// 현재 표시 중인 페이지 인덱스 (0부터 시작)
  int _currentPage = 0;
  
  /// 전체 가이드 페이지 수 (고정값: 5페이지)
  final int _totalPages = 5;
  
  // ===== 가이드 컨텐츠 데이터 =====
  
  /// 각 페이지별 제목과 설명 내용을 담은 리스트
  /// 인덱스 순서: 시작하기 → 타이핑 → 홈화면 → 실시간확인 → 마이페이지
  final List<Map<String, String>> _pages = [
    {
      'title': '🎉 앱테크 시작하기', // 페이지 1: 앱 소개 및 기본 개념
      'content': '타이핑만으로 캐시를 모을 수 있는\n새로운 앱테크 앱에 오신 것을 환영합니다!\n\n💰 10자 입력 = 1캐시\n📅 하루 최대 100캐시까지 적립 가능',
    },
    {
      'title': '⌨️ 타이핑으로 캐시 적립', // 페이지 2: 키보드 기능 사용법
      'content': '키보드 탭에서 자유롭게 타이핑하세요!\n\n✨ 한글, 영어, 숫자 모두 가능\n✨ 문장, 단어, 아무거나 OK\n✨ 타이핑할수록 캐시 증가',
    },
    {
      'title': '🏠 홈화면 활용법', // 페이지 3: 홈화면 UI 요소 설명
      'content': '홈화면에서 진행상황을 확인하세요!\n\n📊 원형 그래프: 오늘의 진행률\n🔴 빨간 숫자: 수집 가능한 캐시\n💎 오른쪽 위: 총 보유 캐시',
    },
    {
      'title': '⚡ 실시간 캐시 확인', // 페이지 4: 실시간 피드백 기능
      'content': '타이핑하는 순간 바로 확인 가능!\n\n📱 키보드 화면에서 실시간 표시\n📈 오늘 입력한 글자 수\n💰 오늘 적립된 캐시\n🎯 세션별 획득 캐시',
    },
    {
      'title': '👤 마이페이지 & 캐시관리', // 페이지 5: 마이페이지 기능 및 향후 계획
      'content': '마이페이지에서 전체 현황 확인!\n\n📊 총 캐시, 오늘 입력, 진행률\n⚙️ 앱 설정 및 정보\n🎁 향후 기프티콘 구매 기능 추가 예정',
    },
  ];

  // ===== 페이지 네비게이션 메서드 =====
  
  /// 다음 페이지로 이동하는 메서드
  /// 마지막 페이지에서는 동작하지 않음
  void _nextPage() {
    if (_currentPage < _totalPages - 1) { // 마지막 페이지 체크
      setState(() {
        _currentPage++; // 다음 페이지로 이동
      });
    }
  }

  /// 이전 페이지로 이동하는 메서드
  /// 첫 번째 페이지에서는 동작하지 않음
  void _previousPage() {
    if (_currentPage > 0) { // 첫 번째 페이지 체크
      setState(() {
        _currentPage--; // 이전 페이지로 이동
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _pages[_currentPage]['title']!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                    iconSize: 24,
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    _pages[_currentPage]['content']!,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            
            // Navigation
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button
                  IconButton(
                    onPressed: _currentPage > 0 ? _previousPage : null,
                    icon: Icon(Icons.arrow_back),
                    color: _currentPage > 0 ? Colors.deepPurple : Colors.grey,
                  ),
                  
                  // Page indicator
                  Text(
                    '${_currentPage + 1} / $_totalPages',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  // Next button
                  IconButton(
                    onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
                    icon: Icon(Icons.arrow_forward),
                    color: _currentPage < _totalPages - 1 ? Colors.deepPurple : Colors.grey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}