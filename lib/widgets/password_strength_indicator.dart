import 'package:flutter/material.dart';

/// 비밀번호 강도를 나타내는 열거형
/// 비밀번호의 보안 수준을 4단계로 분류
enum PasswordStrength {
  /// 매우 약함: 요구사항을 하나도 만족하지 않는 경우
  veryWeak,
  
  /// 약함: 요구사항을 1-2개만 만족하는 경우
  weak,
  
  /// 보통: 요구사항을 3개 만족하는 경우
  medium,
  
  /// 강함: 모든 요구사항(4개)을 만족하는 경우
  strong,
}

/// 비밀번호 강도 분석 결과를 담는 데이터 클래스
/// 강도 수준과 각 조건별 만족 여부를 포함
class PasswordStrengthResult {
  /// 전체적인 비밀번호 강도
  final PasswordStrength strength;
  
  /// 8자 이상 조건 만족 여부
  final bool hasMinLength;
  
  /// 대문자 포함 조건 만족 여부
  final bool hasUppercase;
  
  /// 소문자 포함 조건 만족 여부
  final bool hasLowercase;
  
  /// 숫자 포함 조건 만족 여부
  final bool hasNumbers;
  
  /// 특수문자 포함 조건 만족 여부
  final bool hasSpecialChars;

  const PasswordStrengthResult({
    required this.strength,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumbers,
    required this.hasSpecialChars,
  });
}

/// 비밀번호 강도 분석 유틸리티 클래스
/// 비밀번호의 보안 강도를 체크하고 분석 결과를 제공
class PasswordValidator {
  
  /// 비밀번호 강도를 분석하는 메인 메서드
  /// [password]: 분석할 비밀번호 문자열
  /// Returns: 분석 결과를 담은 PasswordStrengthResult 객체
  static PasswordStrengthResult analyzePassword(String password) {
    // 각 조건별 체크
    final hasMinLength = password.length >= 8;                                    // 8자 이상
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);                    // 대문자 포함
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);                    // 소문자 포함
    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);                      // 숫자 포함
    final hasSpecialChars = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password); // 특수문자 포함

    // 만족하는 조건의 개수를 계산
    int satisfiedConditions = 0;
    if (hasMinLength) satisfiedConditions++;
    if (hasUppercase) satisfiedConditions++;
    if (hasLowercase) satisfiedConditions++;
    if (hasNumbers) satisfiedConditions++;
    if (hasSpecialChars) satisfiedConditions++;

    // 조건 개수에 따른 강도 결정
    PasswordStrength strength;
    if (satisfiedConditions == 0) {
      strength = PasswordStrength.veryWeak;  // 0개: 매우 약함
    } else if (satisfiedConditions <= 2) {
      strength = PasswordStrength.weak;      // 1-2개: 약함
    } else if (satisfiedConditions <= 3) {
      strength = PasswordStrength.medium;    // 3개: 보통
    } else {
      strength = PasswordStrength.strong;    // 4-5개: 강함
    }

    return PasswordStrengthResult(
      strength: strength,
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumbers: hasNumbers,
      hasSpecialChars: hasSpecialChars,
    );
  }

  /// 비밀번호가 강한지 여부를 간단히 체크하는 메서드
  /// [password]: 체크할 비밀번호
  /// Returns: 강한 비밀번호면 true, 아니면 false
  static bool isStrongPassword(String password) {
    final result = analyzePassword(password);
    return result.strength == PasswordStrength.strong;
  }

  /// 비밀번호 유효성 검사 (회원가입/로그인 폼에서 사용)
  /// [password]: 검사할 비밀번호
  /// Returns: 유효하면 null, 유효하지 않으면 에러 메시지 문자열
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return '비밀번호를 입력해주세요';
    }
    
    final result = analyzePassword(password);
    
    // 최소 조건: 8자 이상 + 영문 + 숫자
    if (!result.hasMinLength) {
      return '비밀번호는 8자 이상이어야 합니다';
    }
    if (!result.hasUppercase && !result.hasLowercase) {
      return '영문자를 포함해주세요';
    }
    if (!result.hasNumbers) {
      return '숫자를 포함해주세요';
    }
    
    return null; // 유효한 비밀번호
  }
}

/// 비밀번호 강도를 시각적으로 표시하는 위젯
/// 실시간으로 비밀번호 입력에 반응하여 강도와 조건을 표시
class PasswordStrengthIndicator extends StatelessWidget {
  /// 분석할 비밀번호
  final String password;
  
  /// 상세 조건 표시 여부 (기본값: true)
  final bool showDetails;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final result = PasswordValidator.analyzePassword(password);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 강도 표시 바
        _buildStrengthBar(result.strength),
        
        if (showDetails) ...[
          SizedBox(height: 8),
          // 상세 조건 체크리스트
          _buildConditionsList(result),
        ],
      ],
    );
  }

  /// 비밀번호 강도를 색상 바로 표시하는 위젯
  /// [strength]: 현재 비밀번호 강도
  Widget _buildStrengthBar(PasswordStrength strength) {
    Color strengthColor;
    String strengthText;
    double strengthValue; // 0.0 ~ 1.0

    switch (strength) {
      case PasswordStrength.veryWeak:
        strengthColor = Colors.red;
        strengthText = '매우 약함';
        strengthValue = 0.2;
        break;
      case PasswordStrength.weak:
        strengthColor = Colors.orange;
        strengthText = '약함';
        strengthValue = 0.4;
        break;
      case PasswordStrength.medium:
        strengthColor = Colors.yellow[700]!;
        strengthText = '보통';
        strengthValue = 0.7;
        break;
      case PasswordStrength.strong:
        strengthColor = Colors.green;
        strengthText = '강함';
        strengthValue = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 강도 텍스트
        Row(
          children: [
            Text(
              '비밀번호 강도: ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              strengthText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: strengthColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        
        // 강도 진행바
        Container(
          width: double.infinity,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: strengthValue,
            child: Container(
              decoration: BoxDecoration(
                color: strengthColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 각 조건별 만족 여부를 체크리스트로 표시하는 위젯
  /// [result]: 비밀번호 분석 결과
  Widget _buildConditionsList(PasswordStrengthResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConditionItem('8자 이상', result.hasMinLength),
        _buildConditionItem('대문자 포함', result.hasUppercase),
        _buildConditionItem('소문자 포함', result.hasLowercase),
        _buildConditionItem('숫자 포함', result.hasNumbers),
        _buildConditionItem('특수문자 포함 (!@#\$%^&*)', result.hasSpecialChars),
      ],
    );
  }

  /// 개별 조건의 만족 여부를 표시하는 아이템 위젯
  /// [text]: 조건 설명 텍스트
  /// [isSatisfied]: 조건 만족 여부
  Widget _buildConditionItem(String text, bool isSatisfied) {
    return Padding(
      padding: EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isSatisfied ? Colors.green : Colors.grey[400],
          ),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSatisfied ? Colors.green : Colors.grey[600],
              fontWeight: isSatisfied ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}