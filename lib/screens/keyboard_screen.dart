import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import '../providers/user_provider.dart';

/// AppTech 타이핑 키보드 화면
/// 사용자가 자유롭게 타이핑하여 캐시를 적립할 수 있는 메인 기능 화면
/// 10자당 1캐시 적립, 하루 최대 100캐시 한도
class KeyboardScreen extends StatefulWidget {
  const KeyboardScreen({super.key});
  
  @override
  State<KeyboardScreen> createState() => _KeyboardScreenState();
}

/// KeyboardScreen의 상태 관리 클래스
/// 실시간 타이핑 이벤트 처리, 캐시 적립 로직, 포커스 관리를 담당
class _KeyboardScreenState extends State<KeyboardScreen> {
  
  // ===== 텍스트 입력 관련 컨트롤러 =====
  
  /// 타이핑 텍스트를 관리하는 컨트롤러
  final TextEditingController _textController = TextEditingController();
  
  /// 텍스트 필드의 포커스 상태를 관리하는 노드
  final FocusNode _focusNode = FocusNode();
  
  // ===== 타이핑 통계 상태 변수 =====

  /// 현재 세션에서 입력한 총 글자수
  int _charCount = 0;

  /// 일일 한도 경고를 이미 표시했는지 추적하는 플래그
  bool _hasShownDailyLimitWarning = false;

  // ===== 성능 최적화 관련 변수 =====

  /// 연속된 타이핑 이벤트를 50ms 간격으로 디바운싱하는 타이머
  Timer? _debounceTimer;

  // ===== 위젯 생명주기 관리 메서드 =====
  
  /// 위젯 초기화 메서드
  /// 텍스트 변경 리스너 등록, 자동 포커스 설정
  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged); // 텍스트 변경 감지 리스너 등록
    
    // ===== 자동 포커스 관리 최적화 =====
    // 화면 빌드 완료 후 200ms 딜레이를 두고 텍스트 필드에 자동 포커스
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 200), () { // 200ms 딜레이로 안정적인 포커스
        if (mounted && !_focusNode.hasFocus) {
          try {
            _focusNode.requestFocus(); // 키보드 자동 활성화
          } catch (e) {
            debugPrint('포커스 요청 에러: $e');
          }
        }
      });
    });
  }

  // ===== 텍스트 변경 이벤트 처리 메서드 =====
  
  /// 텍스트 입력 시 실시간으로 호출되는 메서드
  /// 복잡한 로직: 글자수 증가 감지, 디바운싱 처리, 캐시 적립 트리거
  void _onTextChanged() {
    try {
      final newLength = _textController.text.length;
      
      // 글자수가 증가했을 때만 처리 (삭제는 캐시 적립 대상 아님)
      if (newLength > _charCount) {
        final addedChars = newLength - _charCount; // 새로 추가된 글자수
        
        // 추가된 글자가 있을 때만 캐시 적립 로직 실행
        if (addedChars > 0) {
          // ===== 디바운싱 처리 (50ms) =====
          // 빠른 연속 타이핑 시 너무 많은 API 호출 방지
          _debounceTimer?.cancel();                    // 기존 타이머 취소
          _debounceTimer = Timer(Duration(milliseconds: 50), () { // 50ms 딜레이
            if (mounted) {
              _updateTypingCount(addedChars);            // 실제 캐시 적립 처리
            }
          });
        }
      }
      
      // UI 상태 업데이트 (글자수 표시)
      if (mounted) {
        setState(() {
          _charCount = newLength; // 현재 총 글자수 업데이트
        });
      }
    } catch (e) {
      // 키보드 이벤트 처리 중 예외 발생 시 앱 크래시 방지
      debugPrint('텍스트 변경 에러: $e');
    }
  }

  // ===== 캐시 적립 로직 처리 메서드 =====
  
  /// 타이핑한 글자수를 바탕으로 캐시를 적립하는 메서드
  /// 10자당 1캐시 계산, UserProvider 연동
  void _updateTypingCount(int addedChars) {
    // UserProvider를 통해 Firestore에 타이핑 데이터 저장
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    userProvider.updateTypingCount(addedChars); // 실제 DB 업데이트 (낙관적 업데이트)

    // 1000자 도달 시 일일 한도 경고 (한 번만 표시)
    if (!_hasShownDailyLimitWarning && userProvider.currentUser != null) {
      final todayCharCount = userProvider.currentUser!.todayCharCount;

      if (todayCharCount >= 1000) {
        _hasShownDailyLimitWarning = true; // 플래그 설정하여 중복 표시 방지

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ 타이핑 일일 한도(100캐시/1000자)에 도달했습니다!\n광고 시청으로 추가 캐시를 획득하세요.'),
            duration: Duration(seconds: 4),         // 중요한 정보이므로 4초간 표시
            backgroundColor: Colors.red,            // 경고를 나타내는 빨간색 배경
          ),
        );
      }
    }
  }

  // ===== 텍스트 관리 유틸리티 메서드 =====
  
  /// 입력된 텍스트를 모두 지우는 메서드
  /// 글자수 카운트 초기화
  void _clearText() {
    setState(() {
      _textController.clear();  // 텍스트 필드 내용 삭제
      _charCount = 0;           // 현재 세션 글자수 초기화
    });
  }

  // ===== 메인 UI 빌드 메서드 =====
  
  /// 키보드 화면의 UI를 구성하는 메인 빌드 메서드
  /// 포함 요소: 상단 앱바, 통계 카드, 텍스트 입력 영역, 제어 버튼
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경색: 조명
      
      // ===== 상단 앱바 (타이핑 모드 + 보유 캐시 표시) =====
      appBar: AppBar(
        title: Text('타이핑 모드', style: TextStyle(color: Colors.black)), // 화면 제목
        backgroundColor: Colors.white,                                           // 앱바 배경색: 흰색
        elevation: 0,                                                            // 그림자 제거
        automaticallyImplyLeading: false,                                        // 뒤로가기 버튼 비활성화
        // 오른쪽 액션: 사용자의 총 보유 캐시 표시
        actions: [
          Consumer<UserProvider>(
            builder: (context, userProvider, child) {
              final user = userProvider.currentUser;
              return Padding(
                padding: const EdgeInsets.only(right: 16), // 오른쪽 16px 여백
                child: Chip(
                  avatar: Icon(Icons.monetization_on, color: Colors.amber, size: 18), // 앚색 코인 아이콘
                  label: Text('${user?.totalCash ?? 0} 캐시',                            // 총 보유 캐시 표시
                      style: TextStyle(color: Colors.black)),
                  backgroundColor: Colors.grey.shade200,                              // 연한 회색 배경
                ),
              );
            },
          ),
        ],
      ),
      
      // ===== 메인 컨텐츠 영역 =====
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 전체 16px 패딩
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // ===== 상단 통계 카드 (오늘 타이핑 글자수만 표시) =====
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                final user = userProvider.currentUser;
                final todayCharCount = user?.todayCharCount ?? 0;    // 오늘 총 입력 글자수

                // 타이핑 글자수만 표시하는 심플한 카드 (컴팩트)
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // 패딩 축소
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('오늘 타이핑', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('$todayCharCount', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), // 숫자만 크게
                            SizedBox(width: 2),
                            Text('자', style: TextStyle(fontSize: 16, color: Colors.grey)), // 단위
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            
            // ===== 입력 영역 헤더 (제목 + 현재 세션 글자수) =====
            Row(
              children: [
                Text('입력 영역', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // 제목
                Spacer(),                                                                              // 가로 공간 채우기
                Text('$_charCount자', style: TextStyle(fontSize: 16, color: Colors.grey)),           // 현재 세션 글자수
              ],
            ),
            SizedBox(height: 8),
            // ===== 메인 텍스트 입력 영역 (확장 가능한 멀티라인) =====
            Expanded(
              child: Container(
                width: double.infinity,                              // 전체 너비 사용
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300), // 연한 회색 테두리
                  borderRadius: BorderRadius.circular(8),          // 8px 둥근 모서리
                ),
                child: TextField(
                  controller: _textController,                       // 텍스트 컨트롤러 연결
                  focusNode: _focusNode,                             // 포커스 노드 연결
                  maxLines: null,                                    // 무제한 줄바꿈 허용
                  expands: true,                                     // 사용 가능한 공간으로 확장
                  keyboardType: TextInputType.multiline,            // 멀티라인 키보드 활성화
                  textCapitalization: TextCapitalization.none,      // 자동 대문자 변환 비활성화
                  enableIMEPersonalizedLearning: false,             // IME 개인화 학습 비활성화 (개인정보 보호)
                  decoration: InputDecoration(
                    hintText: '여기에 타이핑하세요...\n10자당 1캐시가 적립됩니다!', // 플레이스홀더 안내
                    border: InputBorder.none,                     // 텍스트 필드 자체 테두리 제거 (컨테이너에만 테두리)
                    contentPadding: EdgeInsets.all(16),           // 내부 여백 16px
                  ),
                  style: TextStyle(fontSize: 16),                  // 본문 텍스트 크기
                  // iOS/Android 플랫폼별 키보드 동작 최적화
                  textInputAction: Platform.isIOS 
                      ? TextInputAction.newline                   // iOS: 줄바꿈 버튼
                      : TextInputAction.none,                     // Android: 기본 동작
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // ===== 하단 제어 버튼들 (텍스트 지우기 + 키보드 포커스) =====
            Row(
              children: [
                // 첫 번째 버튼: 입력된 텍스트 전체 삭제
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearText,                       // 텍스트 지우기 기능
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,           // 회색 배경 (대안 기능)
                      foregroundColor: Colors.white,          // 흰색 텍스트
                      padding: EdgeInsets.symmetric(vertical: 16), // 상하 16px 패딩
                    ),
                    child: Text('텍스트 지우기'),
                  ),
                ),
                SizedBox(width: 16), // 버튼 간 16px 간격
                
                // 두 번째 버튼: 키보드 강제 포커스 (키보드가 사라졌을 때 복구)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        if (!_focusNode.hasFocus) {              // 현재 포커스가 없을 때만
                          _focusNode.requestFocus();           // 포커스 요청으로 키보드 활성화
                        }
                      } catch (e) {
                        debugPrint('키보드 포커스 버튼 에러: $e'); // 예외 상황 로깅
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,    // 주 브랜드 색상 (보라색)
                      foregroundColor: Colors.white,         // 흰색 텍스트
                      padding: EdgeInsets.symmetric(vertical: 16), // 상하 16px 패딩
                    ),
                    child: Text('키보드 포커스'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // ===== 하단 도움말 메시지 =====
            // 사용당 캐시 적립 규칙과 일일 한도 안내
            Text(
              '💡 팁: 10자마다 1캐시씩 적립되며, 하루 최대 100캐시까지 획등할 수 있습니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]), // 작은 연한 회색 텍스트
              textAlign: TextAlign.center,                           // 가운데 정렬
            ),
          ],
        ),
      ),
    );
  }

  // ===== 위젯 생명주기 종료 메서드 =====
  
  /// 위젯 해제 시 리소스 정리
  /// 메모리 누수 방지를 위해 타이머, 컨트롤러, 리스너 해제
  @override
  void dispose() {
    try {
      _debounceTimer?.cancel();                           // 디바운스 타이머 취소
      _textController.removeListener(_onTextChanged);     // 텍스트 변경 리스너 제거
      _textController.dispose();                          // 텍스트 컨트롤러 해제
      _focusNode.dispose();                               // 포커스 노드 해제
    } catch (e) {
      debugPrint('dispose 에러: $e'); // 예외 상황 로깅
    }
    super.dispose();
  }
}