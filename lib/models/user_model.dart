import 'package:cloud_firestore/cloud_firestore.dart';

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
    required this.createdAt,       // 계정 생성일
  });

  // ===== Firestore 데이터 변환 팩토리 메서드 =====
  
  /// Firestore DocumentSnapshot에서 UserModel을 생성하는 팩토리 매서드
  /// [doc]: Firestore에서 가져온 사용자 문서 스냅샷
  /// 데이터가 없거나 null인 경우 기본값으로 처리하여 에러 방지
  /// Returns: 변환된 UserModel 인스턴스
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;  // Firestore 데이터를 Map으로 변환
    return UserModel(
      id: doc.id,                                                     // 문서 ID를 사용자 ID로 사용
      email: data['email'] ?? '',                                     // 이메일 (기본값: 빈 문자열)
      totalCash: data['totalCash'] ?? 0,                             // 총 캐시 (기본값: 0)
      todayCharCount: data['todayCharCount'] ?? 0,                   // 오늘 글자수 (기본값: 0)
      collectedCash: data['collectedCash'] ?? 0,                     // 수집한 캐시 (기본값: 0)
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
    DateTime? createdAt,           // 새로운 생성일 (보통 또는 null)
  }) {
    return UserModel(
      id: id ?? this.id,                              // null이면 기존 값 사용
      email: email ?? this.email,                    // null이면 기존 값 사용
      totalCash: totalCash ?? this.totalCash,        // null이면 기존 값 사용
      todayCharCount: todayCharCount ?? this.todayCharCount,      // null이면 기존 값 사용
      collectedCash: collectedCash ?? this.collectedCash,        // null이면 기존 값 사용
      createdAt: createdAt ?? this.createdAt,        // null이면 기존 값 사용
    );
  }
}