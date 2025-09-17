import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../widgets/password_strength_indicator.dart';

/// AppTech 로그인 화면
/// Firebase Authentication을 통한 이메일/비밀번호 로그인 기능 제공
/// 회원가입 화면으로의 네비게이션 및 테스트용 계정 안내 포함
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// LoginScreen의 상태 관리 클래스
/// 로그인 폼 처리, Firebase 인증, 화면 전환을 담당
class _LoginScreenState extends State<LoginScreen> {
  
  // ===== 폼 컨트롤 및 상태 변수 =====
  
  /// 로그인 폼의 validation을 관리하는 GlobalKey
  final _formKey = GlobalKey<FormState>();
  
  /// 이메일 입력 필드 컨트롤러
  final _emailController = TextEditingController();
  
  /// 비밀번호 입력 필드 컨트롤러
  final _passwordController = TextEditingController();
  
  /// 비밀번호 표시/숨김 토글 상태 (false: 숨김, true: 표시)
  bool _isPasswordVisible = false;

  // ===== 생명주기 관리 메서드 =====
  
  /// 위젯 해제 시 리소스 정리
  /// TextEditingController 메모리 해제로 메모리 누수 방지
  @override
  void dispose() {
    _emailController.dispose();   // 이메일 컨트롤러 해제
    _passwordController.dispose(); // 비밀번호 컨트롤러 해제
    super.dispose();
  }

  // ===== Firebase 로그인 처리 메서드 =====
  
  /// 로그인 버튼 클릭 시 실행되는 Firebase 인증 처리 메서드
  /// 폼 validation → Firebase 로그인 → 결과에 따른 UI 피드백 순서로 진행
  Future<void> _handleLogin() async {
    // 1단계: 폼 validation 검사 (이메일 형식, 비밀번호 길이 등)
    if (_formKey.currentState!.validate()) {
      // 2단계: AuthProvider를 통해 Firebase Authentication 접근
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // 3단계: Firebase 로그인 시도
      // trim(): 앞뒤 공백 제거로 입력 오류 방지
      final success = await authProvider.signInWithEmailAndPassword(
        _emailController.text.trim(),  // 이메일 입력값 (공백 제거)
        _passwordController.text.trim(), // 비밀번호 입력값 (공백 제거)
      );

      // 4단계: 로그인 실패 시 사용자에게 에러 메시지 표시
      // mounted 체크: 위젯이 아직 화면에 있는지 확인 (비동기 안전성)
      if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요.'),
            backgroundColor: Colors.red, // 빨간색 배경으로 에러임을 시각적으로 표시
          ),
        );
      }
      // 로그인 성공 시: AuthProvider의 authStateChanges()가 자동으로 HomeScreen으로 이동
    }
  }

  // ===== 화면 네비게이션 메서드 =====
  
  /// 회원가입 화면으로 이동하는 메서드
  /// "회원가입" 텍스트 버튼 클릭 시 실행
  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  /// 비밀번호 찾기 화면으로 이동하는 메서드
  /// "비밀번호 찾기" 텍스트 버튼 클릭 시 실행
  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  // ===== 메인 UI 빌드 메서드 =====
  
  /// 로그인 화면의 전체 UI를 구성하는 메인 빌드 메서드
  /// 앱 로고, 로그인 폼, 회원가입 링크, 테스트 계정 안내로 구성
  @override
  Widget build(BuildContext context) {  
    return Scaffold(
      backgroundColor: Colors.white, // 전체 배경색: 흰색
      resizeToAvoidBottomInset: true, // 키보드가 올라올 때 화면 크기 조정
      body: SafeArea(
        child: SingleChildScrollView( // 키보드 올라와도 스크롤 가능하도록
          physics: ClampingScrollPhysics(), // 부드러운 스크롤 제공
          padding: EdgeInsets.all(24), // 전체 여백 24px
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 가로 전체 너비 사용
            children: [
              SizedBox(height: 20), // 상단 여백 축소 (60 → 20)
              
              // ===== 앱 로고 및 타이틀 섹션 =====
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'AppTech',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '타이핑으로 캐시를 모으세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              // 로그인 폼
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 이메일 입력
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next, // 다음 필드로 이동
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).nextFocus(); // 비밀번호 필드로 포커스 이동
                      },
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
                    
                    SizedBox(height: 12),
                    
                    // 비밀번호 입력
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done, // 완료 액션
                      onFieldSubmitted: (_) => _handleLogin(), // 엔터 시 로그인 실행
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
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호를 입력해주세요';
                        }
                        // 로그인 시에는 기본적인 길이 체크만 (기존 사용자 고려)
                        if (value.length < 6) {
                          return '비밀번호는 6자 이상이어야 합니다';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // 로그인 버튼
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin,
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
                            '로그인',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  );
                },
              ),
              
              SizedBox(height: 12),
              
              // 비밀번호 찾기 링크 (중앙 정렬)
              Center(
                child: TextButton(
                  onPressed: _navigateToForgotPassword,
                  child: Text(
                    '비밀번호를 잊으셨나요?',
                    style: TextStyle(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 12),
              
              // 회원가입 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '아직 계정이 없으신가요? ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: _navigateToRegister,
                    child: Text(
                      '회원가입',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // 임시 데모 계정 안내
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
                          '테스트용 계정',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '이메일: test@example.com\n비밀번호: 123456',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontFamily: 'monospace',
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