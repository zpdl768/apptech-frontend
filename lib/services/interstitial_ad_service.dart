import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 전면 광고를 관리하는 서비스 클래스
/// Google AdMob InterstitialAd의 로딩, 표시, 콜백 처리를 담당
class InterstitialAdService {

  // ===== 광고 ID 상수 =====

  /// Android용 전면 광고 ID (테스트용)
  /// 실제 배포 시에는 AdMob 콘솔에서 발급받은 실제 광고 ID로 변경 필요
  static const String _androidAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  /// iOS용 전면 광고 ID (테스트용)
  /// 실제 배포 시에는 AdMob 콘솔에서 발급받은 실제 광고 ID로 변경 필요
  static const String _iosAdUnitId = 'ca-app-pub-3940256099942544/4411468910';

  // ===== 상태 관리 변수 =====

  /// 현재 로드된 전면 광고 인스턴스
  InterstitialAd? _interstitialAd;

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
  bool get isReady => _interstitialAd != null && !_isShowing;

  /// 현재 광고 로딩 중인지 확인하는 메서드
  /// Returns: 광고 로딩 중인 경우 true
  bool get isLoading => _isLoading;

  // ===== 광고 로딩 메서드 =====

  /// 전면 광고를 로드하는 메서드
  /// [onAdLoaded]: 광고 로딩 성공 시 호출되는 콜백 함수 (선택사항)
  /// [onAdFailedToLoad]: 광고 로딩 실패 시 호출되는 콜백 함수 (선택사항)
  Future<void> loadInterstitialAd({
    VoidCallback? onAdLoaded,
    Function(String error)? onAdFailedToLoad,
  }) async {
    // 이미 로딩 중이거나 광고가 준비된 경우 중복 로딩 방지
    if (_isLoading || _interstitialAd != null) {
      debugPrint('전면 광고: 이미 로딩 중이거나 준비됨');
      return;
    }

    _isLoading = true;
    debugPrint('전면 광고: 로딩 시작');

    try {
      await InterstitialAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          // 광고 로딩 성공 시
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('전면 광고: 로딩 성공');
            _interstitialAd = ad;
            _isLoading = false;

            // 광고 해제 시점 설정 (광고 표시 완료 후 자동 해제)
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                debugPrint('전면 광고: 닫힘');
                _isShowing = false;
                ad.dispose();
                _interstitialAd = null;
                // 다음 광고를 위해 미리 로딩 시작
                loadInterstitialAd(onAdLoaded: onAdLoaded, onAdFailedToLoad: onAdFailedToLoad);
              },
              onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                debugPrint('전면 광고: 표시 실패 - $error');
                _isShowing = false;
                ad.dispose();
                _interstitialAd = null;
                onAdFailedToLoad?.call('광고 표시 실패: ${error.message}');
              },
            );

            // 성공 콜백 호출
            onAdLoaded?.call();
          },

          // 광고 로딩 실패 시
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('전면 광고: 로딩 실패 - $error');
            _isLoading = false;
            _interstitialAd = null;

            // 실패 콜백 호출
            onAdFailedToLoad?.call('광고 로딩 실패: ${error.message}');
          },
        ),
      );
    } catch (e) {
      debugPrint('전면 광고: 로딩 예외 - $e');
      _isLoading = false;
      _interstitialAd = null;
      onAdFailedToLoad?.call('광고 로딩 예외: $e');
    }
  }

  // ===== 광고 표시 메서드 =====

  /// 전면 광고를 표시하는 메서드
  /// [onAdClosed]: 광고가 닫혔을 때 호출되는 콜백
  /// [onAdFailedToShow]: 광고 표시에 실패했을 때 호출되는 콜백
  /// Returns: 광고 표시 시도 성공 여부 (true: 표시 시도, false: 광고 준비되지 않음)
  Future<bool> showInterstitialAd({
    VoidCallback? onAdClosed,
    Function(String error)? onAdFailedToShow,
  }) async {
    // 광고가 준비되지 않은 경우
    if (_interstitialAd == null || _isShowing) {
      debugPrint('전면 광고: 표시 불가 (준비되지 않음)');
      onAdFailedToShow?.call('광고가 준비되지 않았습니다.');
      return false;
    }

    _isShowing = true;

    try {
      // 광고 닫힘 콜백 설정
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          debugPrint('전면 광고: 사용자가 닫음');
          _isShowing = false;
          ad.dispose();
          _interstitialAd = null;
          onAdClosed?.call();
          // 다음 광고를 위해 미리 로딩 시작
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          debugPrint('전면 광고: 표시 실패 - $error');
          _isShowing = false;
          ad.dispose();
          _interstitialAd = null;
          onAdFailedToShow?.call('광고 표시 실패: ${error.message}');
        },
      );

      await _interstitialAd!.show();
      debugPrint('전면 광고: 표시 성공');
      return true;

    } catch (e) {
      debugPrint('전면 광고: 표시 예외 - $e');
      _isShowing = false;
      onAdFailedToShow?.call('광고 표시 예외: $e');
      return false;
    }
  }

  // ===== 리소스 관리 메서드 =====

  /// 리소스를 정리하는 메서드
  /// 앱 종료 시나 서비스 해제 시 호출하여 메모리 누수 방지
  void dispose() {
    debugPrint('전면 광고: 서비스 해제');
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isLoading = false;
    _isShowing = false;
  }

  // ===== 유틸리티 메서드 =====

  /// 현재 상태 정보를 문자열로 반환하는 메서드 (디버깅용)
  /// Returns: 현재 광고 서비스 상태 정보
  String getStatusInfo() {
    return 'InterstitialAdService 상태: '
        'Ready: $isReady, '
        'Loading: $_isLoading, '
        'Showing: $_isShowing, '
        'Ad Instance: ${_interstitialAd != null ? 'Loaded' : 'Null'}';
  }
}
