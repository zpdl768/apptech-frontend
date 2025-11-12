import 'package:flutter/material.dart';

/// AppTech 편의점 카테고리 화면
/// 편의점 브랜드 기프티콘을 선택할 수 있는 화면
/// 상단에 브랜드 버튼들을 가로 스크롤로 표시
class ConvenienceScreen extends StatelessWidget {
  const ConvenienceScreen({super.key});

  // ===== 편의점 브랜드 데이터 =====

  /// 편의점 브랜드 목록
  static final List<String> brands = [
    'CU',
    'GS25',
    '세븐일레븐',
  ];

  // ===== 브랜드 버튼 빌더 메서드 =====

  /// 브랜드 버튼을 생성하는 메서드
  /// [brandName]: 브랜드 이름
  Widget _buildBrandButton(String brandName) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          // 동그란 브랜드 버튼
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,    // 회색 배경 (추후 이미지로 교체)
              shape: BoxShape.circle,         // 동그란 모양
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.store,                  // 편의점 아이콘 (추후 브랜드 이미지로 교체)
                size: 36,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(height: 8),
          // 브랜드 이름
          Text(
            brandName,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ===== 상단 앱바 =====
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '편의점',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      // ===== 메인 콘텐츠 영역 =====
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 브랜드 선택 안내 텍스트
            Text(
              '브랜드 선택',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 16),

            // ===== 가로 스크롤 브랜드 버튼들 =====
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: brands.map((brand) => _buildBrandButton(brand)).toList(),
              ),
            ),
            SizedBox(height: 24),

            // ===== 추후 상품 목록 영역 =====
            Expanded(
              child: Center(
                child: Text(
                  '브랜드를 선택하면 상품 목록이 표시됩니다.\n(추후 구현 예정)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
