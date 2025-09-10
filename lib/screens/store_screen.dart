import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

/// AppTech 상점 화면
/// 사용자가 보유한 캐시로 다양한 기프티콘을 구매할 수 있는 상점 화면
/// 2열 그리드 형태로 상품을 표시하고, 구매 확인 다이얼로그를 통해 안전한 거래 제공
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  
  // ===== 기프티콘 상품 데이터 =====
  
  /// 구매 가능한 기프티콘 목록
  /// 각 아이템은 이름, 가격, 아이콘, 설명으로 구성
  /// 실제 앱에서는 서버에서 받아와야 하는 데이터
  final List<Map<String, dynamic>> giftCards = [
    {
      'name': '스타벅스 아메리카노',                     // 상품명
      'price': 1000,                               // 가격 (캐시 단위)
      'image': Icons.local_cafe,                   // 카페 아이콘
      'description': '스타벅스 아메리카노 쿠폰',        // 상품 설명
    },
    {
      'name': '투썸플레이스 음료',
      'price': 1500,
      'image': Icons.local_cafe,
      'description': '투썸플레이스 음료 쿠폰',
    },
    {
      'name': '맥도날드 세트',
      'price': 3000,
      'image': Icons.fastfood,
      'description': '맥도날드 빅맥 세트',
    },
    {
      'name': '롯데리아 세트',
      'price': 2500,
      'image': Icons.fastfood,
      'description': '롯데리아 불고기 버거 세트',
    },
    {
      'name': 'CGV 영화티켓',
      'price': 5000,
      'image': Icons.movie,
      'description': 'CGV 영화 관람권',
    },
    {
      'name': '컬쳐랜드 문화상품권',
      'price': 10000,
      'image': Icons.card_giftcard,
      'description': '컬쳐랜드 1만원권',
    },
  ];

  // ===== 구매 확인 다이얼로그 표시 메서드 =====
  
  /// 상품 구매 확인 다이얼로그를 표시하는 메서드
  /// [item]: 구매하려는 상품 정보 (이름, 가격, 설명 등)
  /// [userCash]: 사용자의 현재 보유 캐시
  /// 구매 가능 여부를 확인하고 사용자에게 최종 확인을 요청
  void _showPurchaseDialog(Map<String, dynamic> item, int userCash) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('구매 확인'),                          // 다이얼로그 제목
          content: Column(
            mainAxisSize: MainAxisSize.min,                // 최소 크기로 설정
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('상품: ${item['name']}'),                // 선택한 상품명 표시
              Text('가격: ${item['price']} 캐시'),         // 상품 가격 표시
              SizedBox(height: 8),
              Text('현재 보유 캐시: $userCash'),            // 사용자 현재 캐시
              Text('구매 후 캐시: ${userCash - item['price']}'), // 구매 후 예상 캐시
            ],
          ),
          actions: [
            // 취소 버튼
            TextButton(
              onPressed: () => Navigator.of(context).pop(),    // 다이얼로그 닫기
              child: Text('취소'),
            ),
            // 구매 확정 버튼
            ElevatedButton(
              onPressed: userCash >= item['price']             // 캐시 충분할 때만 버튼 활성화
                  ? () {
                      // TODO: 실제 구매 로직 구현 (서버 연동, 결제 처리)
                      Navigator.of(context).pop();             // 구매 확인 다이얼로그 닫기
                      _showPurchaseSuccess(item);               // 구매 성공 다이얼로그 표시
                    }
                  : null,                                      // 캐시 부족시 버튼 비활성화
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,                 // 검은색 버튼
              ),
              child: Text('구매하기'),
            ),
          ],
        );
      },
    );
  }

  // ===== 구매 성공 다이얼로그 표시 메서드 =====
  
  /// 상품 구매 성공을 알리는 다이얼로그를 표시하는 메서드
  /// [item]: 구매 완료된 상품 정보
  /// 구매가 성공적으로 완료되었음을 사용자에게 알림
  void _showPurchaseSuccess(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('구매 완료'),                                    // 성공 메시지 제목
          content: Text('${item['name']}를 성공적으로 구매했습니다!'),   // 구매한 상품명과 성공 메시지
          actions: [
            // 확인 버튼
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),           // 다이얼로그 닫기
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,                       // 검은색 버튼
              ),
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // ===== 메인 UI 빌드 메서드 =====
  
  /// 상점 화면의 UI를 구성하는 메인 빌드 메서드
  /// UserProvider를 통해 사용자 정보를 받아와서 상점 인터페이스 구성
  /// 포함 요소: 상단 캐시 표시, 기프티콘 그리드, 구매 버튼
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.currentUser;     // 현재 로그인된 사용자 정보
        final userCash = user?.totalCash ?? 0;     // 사용자 보유 캐시 (없으면 0)

        return Scaffold(
          backgroundColor: Colors.white,           // 전체 배경색: 흰색
          
          // ===== 상단 앱바 =====
          appBar: AppBar(
            backgroundColor: Colors.white,          // 앱바 배경색: 흰색
            elevation: 0,                           // 그림자 제거
            title: Text(
              '상점',                                // 앱바 제목
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,                      // 제목 중앙 정렬
            automaticallyImplyLeading: false,       // 뒤로가기 버튼 비활성화
            actions: [
              // 사용자 보유 캐시 표시 칩
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Chip(
                  avatar: Icon(Icons.monetization_on, color: Colors.amber, size: 18), // 황금색 코인 아이콘
                  label: Text('$userCash 캐시', style: TextStyle(color: Colors.black)),
                  backgroundColor: Colors.grey.shade200,                                // 연한 회색 배경
                ),
              ),
            ],
          ),
          // ===== 메인 콘텐츠 영역 =====
          body: Padding(
            padding: const EdgeInsets.all(16.0),    // 전체 16px 패딩
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상점 제목 섹션
                Text(
                  '기프티콘',                            // 메인 제목
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                
                // 상점 설명 텍스트
                Text(
                  '캐시로 다양한 기프티콘을 구매하세요!',   // 설명 문구
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 24),
                // ===== 기프티콘 그리드 뷰 =====
                // 2열 그리드 형태로 기프티콘 상품들을 표시
                Expanded(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,              // 2열 그리드
                      crossAxisSpacing: 16,           // 가로 간격 16px
                      mainAxisSpacing: 16,            // 세로 간격 16px
                      childAspectRatio: 0.8,          // 카드 비율 (세로가 더 긴 직사각형)
                    ),
                    itemCount: giftCards.length,       // 기프티콘 개수
                    itemBuilder: (context, index) {
                      final item = giftCards[index];                    // 현재 상품 정보
                      final canPurchase = userCash >= item['price'];   // 구매 가능 여부 (캐시 충분한지 확인)

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Icon(
                                  item['image'],
                                  size: 48,
                                  color: canPurchase ? Colors.black : Colors.grey,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                item['name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: canPurchase ? Colors.black : Colors.grey,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                item['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item['price']} 캐시',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: canPurchase
                                        ? () => _showPurchaseDialog(item, userCash)
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canPurchase ? Colors.black : Colors.grey,
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size(60, 28),
                                    ),
                                    child: Text(
                                      '구매',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}