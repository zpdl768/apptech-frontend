import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 리워드 광고를 관리하는 서비스 클래스
/// Google AdMob RewardedAd의 로딩, 표시, 콜백 처리를 담당
class RewardAdService {
  
  // ===== 광고 ID 상수 =====
  
  /// Android용 리워드 광고 ID (테스트용)
  /// 실제 배포 시에는 AdMob 콘솔에서 발급받은 실제 광고 ID로 변경 필요
  static const String _androidAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  
  /// iOS용 리워드 광고 ID (테스트용)
  /// 실제 배포 시에는 AdMob 콘솔에서 발급받은 실제 광고 ID로 변경 필요
  static const String _iosAdUnitId = 'ca-app-pub-3940256099942544/1712485313';
  
  // ===== 상태 관리 변수 =====
  
  /// 현재 로드된 리워드 광고 인스턴스
  RewardedAd? _rewardedAd;
  
  /// 광고 로딩 상태 (true: 로딩 중, false: 로딩 완료 또는 미시작)
  bool _isLoading = false;
  
  /// 광고 표시 중인지 여부 (true: 표시 중, false: 표시되지 않음)
  bool _isShowing = false;
  
  // ===== Getter 메서드 =====
  
  /// 플랫폼별 광고 ID를 반환하는 메서드
  String get _adUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidAdUnitId;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _iosAdUnitId;
    } else {
      return _androidAdUnitId; // 기본값: Android ID 사용
    }
  }
  
  /// 광고가 준비되었는지 확인하는 메서드
  /// Returns: 광고가 로드되고 표시 준비가 완료된 경우 true
  bool get isReady => _rewardedAd != null && !_isShowing;
  
  /// 현재 광고 로딩 중인지 확인하는 메서드
  /// Returns: 광고 로딩 중인 경우 true
  bool get isLoading => _isLoading;
  
  // ===== 광고 로딩 메서드 =====
  
  /// 리워드 광고를 로드하는 메서드
  /// [onAdLoaded]: 광고 로딩 성공 시 호출되는 콜백 함수 (선택사항)
  /// [onAdFailedToLoad]: 광고 로딩 실패 시 호출되는 콜백 함수 (선택사항)
  Future<void> loadRewardedAd({
    VoidCallback? onAdLoaded,
    Function(String error)? onAdFailedToLoad,
  }) async {
    // 이미 로딩 중이거나 광고가 준비된 경우 중복 로딩 방지
    if (_isLoading || _rewardedAd != null) {
      debugPrint('리워드 광고: 이미 로딩 중이거나 준비됨');
      return;
    }
    
    _isLoading = true;
    debugPrint('리워드 광고: 로딩 시작');
    
    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          // 광고 로딩 성공 시
          onAdLoaded: (RewardedAd ad) {
            debugPrint('리워드 광고: 로딩 성공');
            _rewardedAd = ad;
            _isLoading = false;
            
            // 광고 해제 시점 설정 (광고 표시 완료 후 자동 해제)
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                debugPrint('리워드 광고: 닫힘');
                _isShowing = false;
                ad.dispose();
                _rewardedAd = null;
                // 다음 광고를 위해 미리 로딩 시작
                loadRewardedAd(onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad);
              },
              onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
                debugPrint('리워드 광고: 표시 실패 - $error');
                _isShowing = false;
                ad.dispose();
                _rewardedAd = null;
                onAdFailedToLoad?.call('광고 표시 실패: ${error.message}');
              },
            );
            
            // 성공 콜백 호출
            onAdLoaded?.call();
          },
          
          // 광고 로딩 실패 시
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('리워드 광고: 로딩 실패 - $error');
            _isLoading = false;
            _rewardedAd = null;
            
            // 실패 콜백 호출
            onAdFailedToLoad?.call('광고 로딩 실패: ${error.message}');
          },
        ),
      );
    } catch (e) {
      debugPrint('리워드 광고: 로딩 예외 - $e');
      _isLoading = false;
      _rewardedAd = null;
      onAdFailedToLoad?.call('광고 로딩 예외: $e');
    }
  }
  
  // ===== 광고 표시 메서드 =====
  
  /// 리워드 광고를 표시하는 메서드
  /// [onUserEarnedReward]: 사용자가 광고를 끝까지 시청하여 보상을 획득했을 때 호출되는 콜백
  /// [onAdClosed]: 광고가 닫혔을 때 호출되는 콜백 (보상 획득 여부와 관계없이)
  /// [onAdFailedToShow]: 광고 표시에 실패했을 때 호출되는 콜백
  /// Returns: 광고 표시 시도 성공 여부 (true: 표시 시도, false: 광고 준비되지 않음)
  Future<bool> showRewardedAd({
    required Function(int rewardAmount) onUserEarnedReward,
    VoidCallback? onAdClosed,
    Function(String error)? onAdFailedToShow,
  }) async {
    // 광고가 준비되지 않은 경우
    if (_rewardedAd == null || _isShowing) {
      debugPrint('리워드 광고: 표시 불가 (준비되지 않음)');
      onAdFailedToShow?.call('광고가 준비되지 않았습니다.');
      return false;
    }
    
    _isShowing = true;
    
    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('리워드 광고: 보상 획득 - ${reward.type}: ${reward.amount}');
          
          // 8-11 사이의 랜덤 캐시로 고정 (AdMob 보상값 무시)
          // 이는 게임 밸런스를 위한 설계
          final randomReward = 8 + (reward.amount.toInt() % 4); // 8, 9, 10, 11 중 하나
          onUserEarnedReward(randomReward);
        },
      );
      
      debugPrint('리워드 광고: 표시 성공');
      return true;
      
    } catch (e) {
      debugPrint('리워드 광고: 표시 예외 - $e');
      _isShowing = false;
      onAdFailedToShow?.call('광고 표시 예외: $e');
      return false;
    }
  }
  
  // ===== 리소스 관리 메서드 =====
  
  /// 리소스를 정리하는 메서드
  /// 앱 종료 시나 서비스 해제 시 호출하여 메모리 누수 방지
  void dispose() {
    debugPrint('리워드 광고: 서비스 해제');
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isLoading = false;
    _isShowing = false;
  }
  
  // ===== 유틸리티 메서드 =====
  
  /// 현재 상태 정보를 문자열로 반환하는 메서드 (디버깅용)
  /// Returns: 현재 광고 서비스 상태 정보
  String getStatusInfo() {
    return 'RewardAdService 상태: '
        'Ready: $isReady, '
        'Loading: $_isLoading, '
        'Showing: $_isShowing, '
        'Ad Instance: ${_rewardedAd != null ? 'Loaded' : 'Null'}';
  }
}