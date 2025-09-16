import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/password_strength_indicator.dart';

/// AppTech 회원가입 화면
/// Firebase Authentication을 통한 이메일/비밀번호 회원가입 기능 제공
/// 비밀번호 확인, 자동 로그인, 개인정보 처리 안내 포함
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

/// RegisterScreen의 상태 관리 클래스
/// 회원가입 폼 처리, Firebase 인증, 비밀번호 확인, 자동 로그인을 담당
class _RegisterScreenState extends State<RegisterScreen> {
  
  // ===== 폼 컨트롤 및 상태 변수 =====
  
  /// 회원가입 폼의 validation을 관리하는 GlobalKey
  final _formKey = GlobalKey<FormState>();
  
  /// 이메일 입력 필드 컨트롤러
  final _emailController = TextEditingController();
  
  /// 비밀번호 입력 필드 컨트롤러
  final _passwordController = TextEditingController();
  
  /// 비밀번호 확인 입력 필드 컨트롤러
  final _confirmPasswordController = TextEditingController();
  
  /// 비밀번호 표시/숨김 토글 상태 (false: 숨김, true: 표시)
  bool _isPasswordVisible = false;
  
  /// 비밀번호 확인 표시/숨김 토글 상태 (false: 숨김, true: 표시)
  bool _isConfirmPasswordVisible = false;

  // ===== 생명주기 관리 메서드 =====
  
  /// 위젯 초기화 메서드
  /// 비밀번호 입력 시 실시간 강도 표시를 위한 리스너 설정
  @override
  void initState() {
    super.initState();
    // 비밀번호 입력 시 실시간 UI 업데이트를 위한 리스너 추가
    _passwordController.addListener(() {
      setState(() {}); // 비밀번호 변경 시 UI 새로고침
    });
  }

  /// 위젯 해제 시 리소스 정리
  /// TextEditingController 메모리 해제로 메모리 누수 방지
  @override
  void dispose() {
    _emailController.dispose();           // 이메일 컨트롤러 해제
    _passwordController.dispose();        // 비밀번호 컨트롤러 해제
    _confirmPasswordController.dispose(); // 비밀번호 확인 컨트롤러 해제
    super.dispose();
  }

  // ===== Firebase 회원가입 처리 메서드 =====
  
  /// 회원가입 버튼 클릭 시 실행되는 Firebase 인증 처리 메서드
  /// 폼 validation → 비밀번호 일치 확인 → Firebase 회원가입 → 자동 로그인 순서로 진행
  Future<void> _handleRegister() async {
    // 1단계: 폼 validation 검사 (이메일 형식, 비밀번호 길이 등)
    if (_formKey.currentState!.validate()) {
      
      // 2단계: 비밀번호 일치 확인 (중요한 보안 체크)
      // TextFormField validator로는 두 필드 비교가 어려우므로 여기서 처리
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('비밀번호가 일치하지 않습니다.'),
            backgroundColor: Colors.red, // 빨간색으로 에러 표시
          ),
        );
        return; // 일치하지 않으면 회원가입 중단
      }

      // 3단계: AuthProvider를 통해 Firebase Authentication 접근
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // 4단계: Firebase 회원가입 시도
      // trim(): 앞뒤 공백 제거로 입력 오류 방지
      final success = await authProvider.signUpWithEmailAndPassword(
        _emailController.text.trim(),    // 이메일 입력값 (공백 제거)
        _passwordController.text.trim(), // 비밀번호 입력값 (공백 제거)
      );

      // 5단계: 회원가입 결과에 따른 사용자 피드백
      // mounted 체크: 위젯이 아직 화면에 있는지 확인 (비동기 안전성)
      if (mounted) {
        if (success) {
          // 회원가입 성공: 초록색 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('회원가입이 완료되었습니다! 로그인해주세요.'),
              backgroundColor: Colors.green, // 초록색 배경으로 성공임을 시각적으로 표시
            ),
          );
          // Firebase는 회원가입 성공 시 자동으로 로그인 상태로 만들어줌
          // AuthProvider의 authStateChanges()가 자동으로 HomeScreen으로 이동
        } else {
          // 회원가입 실패: 빨간색 에러 메시지 표시 (이메일 중복, 네트워크 오류 등)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('회원가입에 실패했습니다. 다시 시도해주세요.'),
              backgroundColor: Colors.red, // 빨간색 배경으로 에러임을 시각적으로 표시
            ),
          );
        }
      }
    }
  }

  // ===== 메인 UI 빌드 메서드 =====
  
  /// 회원가입 화면의 전체 UI를 구성하는 메인 빌드 메서드
  /// 앱 로고, 회원가입 폼, 로그인 화면 링크, 개인정보 안내로 구성
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경색: 흰색
      
      // ===== 상단 앱바 (뒤로가기 버튼 + 제목) =====
      appBar: AppBar(
        backgroundColor: Colors.white,  // 앱바 배경색: 흰색
        elevation: 0,                   // 그림자 제거
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black), // 뒤로가기 아이콘 (검은색)
          onPressed: () => Navigator.pop(context),           // 로그인 화면으로 돌아가기
        ),
        title: Text('회원가입', style: TextStyle(color: Colors.black)), // 화면 제목 (검은색)
      ),
      
      // ===== 메인 콘텐츠 영역 =====
      body: SafeArea(
        child: SingleChildScrollView( // 키보드 올라와도 스크롤 가능하도록
          padding: EdgeInsets.all(24), // 전체 여백 24px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 가로 전체 너비 사용
            children: [
              SizedBox(height: 20), // 상단 여백
              
              // ===== 앱 로고 및 타이틀 섹션 =====
              Center(
                child: Column(
                  children: [
                    // 회원가입 로고 컨테이너 (80x80 보라색 둥근 사각형)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,         // 보라색 배경
                        borderRadius: BorderRadius.circular(20), // 둥근 모서리
                      ),
                      child: Icon(
                        Icons.person_add, // 사용자 추가 아이콘 (회원가입 의미)
                        color: Colors.white, // 흰색 아이콘
                        size: 40,            // 아이콘 크기
                      ),
                    ),
                    SizedBox(height: 16),
                    // 회원가입 제목
                    Text(
                      '새 계정 만들기',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple, // 보라색 텍스트
                      ),
                    ),
                    SizedBox(height: 8),
                    // 회원가입 설명/슬로건
                    Text(
                      'AppTech에서 캐시를 모아보세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600], // 회색 텍스트
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40),
              
              // 회원가입 폼
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 이메일 입력
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: '이메일',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일을 입력해주세요';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return '올바른 이메일 형식을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // 비밀번호 입력
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                        helperText: '8자 이상, 영문, 숫자 포함',
                        helperStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        // 강화된 비밀번호 정책 적용
                        return PasswordValidator.validatePassword(value);
                      },
                    ),
                    
                    SizedBox(height: 8),
                    
                    // 비밀번호 강도 표시기
                    PasswordStrengthIndicator(
                      password: _passwordController.text,
                      showDetails: true,
                    ),
                    
                    SizedBox(height: 16),
                    
                    // 비밀번호 확인
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: '비밀번호 확인',
                        prefixIcon: Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호 확인을 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // 회원가입 버튼
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: authProvider.isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            '회원가입',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                },
              ),
              
              SizedBox(height: 24),
              
              // 로그인으로 이동
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '이미 계정이 있으신가요? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      '로그인',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 40),
              
              // 정보 안내
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.deepPurple, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '개인정보 처리',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '회원가입 시 AppTech의 이용약관 및 개인정보처리방침에 동의한 것으로 간주됩니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}