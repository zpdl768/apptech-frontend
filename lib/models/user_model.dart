import 'package:cloud_firestore/cloud_firestore.dart';

/// 캐시 상자의 상태를 나타내는 열거형
/// 100자 단위로 활성화되는 리워드 상자의 3가지 상태
enum BoxState {
  /// 타이핑 부족으로 잠긴 상태 (회색, 터치 불가)
  locked,
  
  /// 광고 시청 가능한 활성화 상태 (황금색, 터치 가능)  
  available,
  
  /// 광고 시청 완료 상태 (초록색, "수집 완료", 터치 불가)
  completed,
}

/// AppTech 사용자 데이터 모델 클래스
/// Firestore와 앞창에서 사용할 사용자 정보를 담는 데이터 모델
/// 캐시 적립, 일일 타이핑 현황, 수집 상태 등의 게임 요소를 담당
/// immutable 클래스로 설계하여 데이터 안전성 보장
class UserModel {
  // ===== 사용자 기본 정보 필드들 =====
  
  /// Firebase UID (Firestore 문서 ID와 동일)
  final String id;
  
  /// 사용자 이메일 주소
  final String email;
  
  /// 누적 총 보유 캐시 (촜기화되지 않는 전체 캐시)
  final int totalCash;
  
  /// 오늘 타이핑한 총 글자수 (10글자당 1캐시 적립 원칙)
  final int todayCharCount;
  
  /// 오늘 수집한 캐시 개수 (todayCharCount에서 수집한 비율)
  final int collectedCash;
  
  /// 오늘 획득한 총 캐시 (일일 800캐시 한도 관리용)
  final int dailyCashEarned;
  
  /// 리워드 광고 상자들의 상태 (10개, 100자 단위로 활성화)
  /// [0]: 100자, [1]: 200자, [2]: 300자, ... [9]: 1000자
  final List<BoxState> boxStates;
  
  /// 마지막 일일 리셋 날짜 (부정행위 방지용)
  final DateTime? lastResetDate;
  
  /// 계정 생성 일시 (회원가입 날짜)
  final DateTime createdAt;

  // ===== 생성자 =====
  
  /// UserModel 생성자
  /// 모든 필드가 required로 설정되어 데이터 무결성 보장
  /// const 생성자로 컴파일 타임 최적화 제공
  const UserModel({
    required this.id,              // Firebase UID (Firestore 문서 ID)
    required this.email,           // 사용자 이메일
    required this.totalCash,       // 누적 캐시
    required this.todayCharCount,  // 오늘 타이핑 글자수
    required this.collectedCash,   // 오늘 수집한 캐시
    required this.dailyCashEarned, // 오늘 획득한 총 캐시
    required this.boxStates,       // 리워드 상자 상태 배열
    this.lastResetDate,           // 마지막 리셋 날짜 (선택적)
    required this.createdAt,       // 계정 생성일
  });

  // ===== Firestore 데이터 변환 팩토리 메서드 =====
  
  /// Firestore DocumentSnapshot에서 UserModel을 생성하는 팩토리 매서드
  /// [doc]: Firestore에서 가져온 사용자 문서 스냅샷
  /// 데이터가 없거나 null인 경우 기본값으로 처리하여 에러 방지
  /// Returns: 변환된 UserModel 인스턴스
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;  // Firestore 데이터를 Map으로 변환
    
    // 상자 상태 배열 파싱 (기본값: 모든 상자 잠김 상태)
    List<BoxState> boxStates;
    if (data['boxStates'] != null) {
      List<dynamic> boxStatesData = data['boxStates'];
      boxStates = boxStatesData.map((state) => BoxState.values[state as int]).toList();
    } else {
      boxStates = List.generate(10, (index) => BoxState.locked); // 10개 상자 모두 잠김 상태로 초기화
    }
    
    return UserModel(
      id: doc.id,                                                     // 문서 ID를 사용자 ID로 사용
      email: data['email'] ?? '',                                     // 이메일 (기본값: 빈 문자열)
      totalCash: data['totalCash'] ?? 0,                             // 총 캐시 (기본값: 0)
      todayCharCount: data['todayCharCount'] ?? 0,                   // 오늘 글자수 (기본값: 0)
      collectedCash: data['collectedCash'] ?? 0,                     // 수집한 캐시 (기본값: 0)
      dailyCashEarned: data['dailyCashEarned'] ?? 0,                 // 오늘 획득 캐시 (기본값: 0)
      boxStates: boxStates,                                          // 상자 상태 배열
      lastResetDate: (data['lastResetDate'] as Timestamp?)?.toDate(), // 마지막 리셋 날짜
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(), // 생성일 (기본값: 현재시간)
    );
  }

  // ===== Firestore 저장용 데이터 변환 메서드 =====
  
  /// UserModel을 Firestore에 저장할 수 있는 Map 형태로 변환하는 메서드
  /// Firestore에서 지원하는 데이터 타입으로 변환 (DateTime → Timestamp)
  /// id는 문서 ID로 사용되므로 데이터에 포함하지 않음
  /// Returns: Firestore에 저장 가능한 Map<String, dynamic>
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,                            // 사용자 이메일
      'totalCash': totalCash,                    // 누적 총 캐시
      'todayCharCount': todayCharCount,          // 오늘 타이핑 글자수
      'collectedCash': collectedCash,            // 오늘 수집한 캐시
      'dailyCashEarned': dailyCashEarned,        // 오늘 획득한 총 캐시
      'boxStates': boxStates.map((state) => state.index).toList(), // BoxState enum을 정수 배열로 변환
      'lastResetDate': lastResetDate != null ? Timestamp.fromDate(lastResetDate!) : null, // 마지막 리셋 날짜
      'createdAt': Timestamp.fromDate(createdAt), // DateTime을 Firestore Timestamp로 변환
    };
  }

  // ===== 부분 업데이트를 위한 복사 메서드 =====
  
  /// 기존 UserModel에서 일부 필드만 변경한 새로운 UserModel을 생성하는 메서드
  /// immutable 객체의 상태 변경을 위한 일반적인 Flutter 패턴
  /// 변경하고 싶지 않은 필드는 null로 두면 기존 값 유지
  /// 
  /// 예시: user.copyWith(totalCash: 150) // 캐시만 다른 값으로 변경
  UserModel copyWith({
    String? id,                    // 새로운 ID (보통 또는 null)
    String? email,                 // 새로운 이메일 (보통 또는 null)
    int? totalCash,                // 새로운 총 캐시
    int? todayCharCount,           // 새로운 오늘 글자수
    int? collectedCash,            // 새로운 수집 캐시
    int? dailyCashEarned,          // 새로운 일일 획득 캐시
    List<BoxState>? boxStates,     // 새로운 상자 상태 배열
    DateTime? lastResetDate,       // 새로운 리셋 날짜
    DateTime? createdAt,           // 새로운 생성일 (보통 또는 null)
  }) {
    return UserModel(
      id: id ?? this.id,                              // null이면 기존 값 사용
      email: email ?? this.email,                    // null이면 기존 값 사용
      totalCash: totalCash ?? this.totalCash,        // null이면 기존 값 사용
      todayCharCount: todayCharCount ?? this.todayCharCount,      // null이면 기존 값 사용
      collectedCash: collectedCash ?? this.collectedCash,        // null이면 기존 값 사용
      dailyCashEarned: dailyCashEarned ?? this.dailyCashEarned,  // null이면 기존 값 사용
      boxStates: boxStates ?? this.boxStates,        // null이면 기존 값 사용
      lastResetDate: lastResetDate ?? this.lastResetDate,        // null이면 기존 값 사용
      createdAt: createdAt ?? this.createdAt,        // null이면 기존 값 사용
    );
  }
  
  // ===== 편의 메서드들 =====
  
  /// 특정 인덱스의 상자 상태를 반환하는 메서드
  /// [index]: 상자 인덱스 (0~9)
  /// Returns: 해당 상자의 상태
  BoxState getBoxState(int index) {
    if (index < 0 || index >= 10) return BoxState.locked;
    return boxStates[index];
  }
  
  /// 해당 인덱스의 상자가 사용 가능한지 확인하는 메서드
  /// [index]: 확인할 상자 인덱스 (0~9)
  /// Returns: 사용 가능하면 true (타이핑 충분 + 아직 사용 안함)
  bool canUseBox(int index) {
    if (index < 0 || index >= 10) return false;
    
    // 해당 상자 활성화에 필요한 글자수 (100자 단위)
    final requiredChars = (index + 1) * 100;
    
    // 조건: 충분히 타이핑했고, 상자가 잠긴 상태일 때만 사용 가능
    return todayCharCount >= requiredChars && boxStates[index] == BoxState.locked;
  }
  
  /// 일일 리셋을 위해 모든 상자를 잠김 상태로 초기화하는 메서드
  /// Returns: 모든 상자가 locked 상태로 설정된 새로운 UserModel
  UserModel resetDailyBoxes() {
    return copyWith(
      boxStates: List.generate(10, (index) => BoxState.locked),
      todayCharCount: 0,
      collectedCash: 0,
      dailyCashEarned: 0,
      lastResetDate: DateTime.now(),
    );
  }
  
  /// 일일 캐시 획득 한도를 확인하는 메서드
  /// Returns: 800캐시 한도까지 남은 캐시 양 (0이면 한도 달성)
  int getRemainingDailyCash() {
    const maxDailyCash = 800;
    return (maxDailyCash - dailyCashEarned).clamp(0, maxDailyCash);
  }
  
  /// 일일 캐시 진행률 반환 (0.0 ~ 1.0)
  /// Returns: 800캐시 중 현재까지 획득한 비율
  double getDailyCashProgress() {
    const maxDailyCash = 800;
    return (dailyCashEarned / maxDailyCash).clamp(0.0, 1.0);
  }
}