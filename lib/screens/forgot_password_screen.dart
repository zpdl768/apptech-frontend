import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// AppTech 비밀번호 재설정 화면
/// Firebase Authentication을 통한 비밀번호 재설정 이메일 발송 기능 제공
/// 사용자가 이메일 주소를 입력하면 Firebase에서 비밀번호 재설정 링크를 발송
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

/// ForgotPasswordScreen의 상태 관리 클래스
/// 이메일 폼 처리, Firebase 비밀번호 재설정, 사용자 피드백을 담당
class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  
  // ===== 폼 컨트롤 및 상태 변수 =====
  
  /// 비밀번호 재설정 폼의 validation을 관리하는 GlobalKey
  final _formKey = GlobalKey<FormState>();
  
  /// 이메일 입력 필드 컨트롤러
  final _emailController = TextEditingController();
  
  /// 이메일 발송 성공 상태 (성공 메시지 표시용)
  bool _emailSent = false;

  // ===== 생명주기 관리 메서드 =====
  
  /// 위젯 해제 시 리소스 정리
  /// TextEditingController 메모리 해제로 메모리 누수 방지
  @override
  void dispose() {
    _emailController.dispose();   // 이메일 컨트롤러 해제
    super.dispose();
  }

  // ===== Firebase 비밀번호 재설정 처리 메서드 =====
  
  /// 비밀번호 재설정 버튼 클릭 시 실행되는 Firebase 처리 메서드
  /// 폼 validation → Firebase 비밀번호 재설정 이메일 발송 → 결과 피드백 순서로 진행
  Future<void> _handlePasswordReset() async {
    // 1단계: 폼 validation 검사 (이메일 형식 검증)
    if (_formKey.currentState!.validate()) {
      
      // 2단계: AuthProvider를 통해 Firebase Authentication 접근
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // 3단계: Firebase 비밀번호 재설정 이메일 발송 시도
      // trim(): 앞뒤 공백 제거로 입력 오류 방지
      final success = await authProvider.sendPasswordResetEmail(
        _emailController.text.trim(),  // 이메일 입력값 (공백 제거)
      );

      // 4단계: 발송 결과에 따른 사용자 피드백
      // mounted 체크: 위젯이 아직 화면에 있는지 확인 (비동기 안전성)
      if (mounted) {
        if (success) {
          // 발송 성공: 성공 상태로 변경하여 UI 업데이트
          setState(() {
            _emailSent = true;  // 성공 메시지 화면으로 전환
          });
        } else {
          // 발송 실패: 빨간색 에러 메시지 표시 (이메일 없음, 네트워크 오류 등)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('비밀번호 재설정 이메일 발송에 실패했습니다. 이메일 주소를 확인해주세요.'),
              backgroundColor: Colors.red, // 빨간색 배경으로 에러임을 시각적으로 표시
            ),
          );
        }
      }
    }
  }

  // ===== 메인 UI 빌드 메서드 =====
  
  /// 비밀번호 재설정 화면의 전체 UI를 구성하는 메인 빌드 메서드
  /// 이메일 발송 전/후 상태에 따라 다른 UI 표시
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
        title: Text('비밀번호 찾기', style: TextStyle(color: Colors.black)), // 화면 제목 (검은색)
      ),
      
      // ===== 메인 콘텐츠 영역 =====
      body: SafeArea(
        child: SingleChildScrollView( // 키보드 올라와도 스크롤 가능하도록
          padding: EdgeInsets.all(24), // 전체 여백 24px
          child: _emailSent ? _buildSuccessView() : _buildEmailForm(), // 상태에 따른 화면 전환
        ),
      ),
    );
  }

  // ===== 이메일 입력 폼 UI 구성 메서드 =====
  
  /// 비밀번호 재설정 이메일 입력 폼을 구성하는 메서드
  /// 아이콘, 설명, 이메일 입력 필드, 발송 버튼으로 구성
  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // 가로 전체 너비 사용
      children: [
        SizedBox(height: 40), // 상단 여백
        
        // ===== 비밀번호 재설정 아이콘 및 제목 섹션 =====
        Center(
          child: Column(
            children: [
              // 비밀번호 재설정 아이콘 컨테이너 (80x80 보라색 둥근 사각형)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,         // 보라색 배경
                  borderRadius: BorderRadius.circular(20), // 둥근 모서리
                ),
                child: Icon(
                  Icons.lock_reset,  // 자물쇠 재설정 아이콘 (비밀번호 재설정 의미)
                  color: Colors.white, // 흰색 아이콘
                  size: 40,            // 아이콘 크기
                ),
              ),
              SizedBox(height: 24),
              
              // 비밀번호 재설정 제목
              Text(
                '비밀번호 재설정',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple, // 보라색 텍스트
                ),
              ),
              SizedBox(height: 16),
              
              // 비밀번호 재설정 설명 텍스트
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '가입하신 이메일 주소를 입력해주세요.\n비밀번호 재설정 링크를 발송해드립니다.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600], // 회색 텍스트
                    height: 1.5,             // 줄간격
                  ),
                  textAlign: TextAlign.center, // 가운데 정렬
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 50),
        
        // ===== 이메일 입력 폼 =====
        Form(
          key: _formKey,
          child: Column(
            children: [
              // 이메일 입력 필드
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: '이메일 주소',                    // 라벨 텍스트
                  hintText: 'your@email.com',               // 플레이스홀더
                  prefixIcon: Icon(Icons.email_outlined),   // 이메일 아이콘
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // 둥근 테두리
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2), // 포커스 시 보라색 테두리
                  ),
                ),
                validator: (value) {
                  // 이메일 형식 검증 로직
                  if (value == null || value.isEmpty) {
                    return '이메일을 입력해주세요';
                  }
                  // 이메일 정규 표현식으로 형식 검증
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return '올바른 이메일 형식을 입력해주세요';
                  }
                  return null; // 검증 성공
                },
              ),
            ],
          ),
        ),
        
        SizedBox(height: 32),
        
        // ===== 비밀번호 재설정 이메일 발송 버튼 =====
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            return ElevatedButton(
              onPressed: authProvider.isLoading ? null : _handlePasswordReset, // 로딩 중에는 버튼 비활성화
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // 보라색 배경
                foregroundColor: Colors.white,      // 흰색 텍스트
                padding: EdgeInsets.symmetric(vertical: 16), // 상하 16px 패딩
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // 둥근 모서리
                ),
                elevation: 0, // 그림자 제거 (플랫 디자인)
              ),
              child: authProvider.isLoading
                  ? // 로딩 중: 흰색 로딩 스피너 표시
                    SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : // 정상 상태: 버튼 텍스트 표시
                    Text(
                      '재설정 이메일 발송',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            );
          },
        ),
        
        SizedBox(height: 24),
        
        // ===== 로그인으로 돌아가기 링크 =====
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '비밀번호가 생각났나요? ',
              style: TextStyle(color: Colors.grey[600]),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context), // 로그인 화면으로 돌아가기
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
      ],
    );
  }

  // ===== 이메일 발송 성공 화면 UI 구성 메서드 =====
  
  /// 비밀번호 재설정 이메일 발송 성공 시 표시되는 화면 구성 메서드
  /// 성공 아이콘, 안내 메시지, 추가 설명, 확인 버튼으로 구성
  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // 가로 전체 너비 사용
      children: [
        SizedBox(height: 60), // 상단 여백
        
        // ===== 성공 아이콘 및 메시지 섹션 =====
        Center(
          child: Column(
            children: [
              // 성공 아이콘 컨테이너 (100x100 초록색 원형)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green,            // 초록색 배경 (성공 의미)
                  borderRadius: BorderRadius.circular(50), // 완전한 원형
                ),
                child: Icon(
                  Icons.mark_email_read,  // 이메일 읽음 확인 아이콘 (발송 성공 의미)
                  color: Colors.white,    // 흰색 아이콘
                  size: 50,               // 큰 아이콘 크기
                ),
              ),
              SizedBox(height: 32),
              
              // 성공 메시지 제목
              Text(
                '이메일을 발송했습니다!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // 검은색 텍스트
                ),
              ),
              SizedBox(height: 16),
              
              // 성공 상세 설명
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      '${_emailController.text}로\n비밀번호 재설정 링크를 발송했습니다.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600], // 회색 텍스트
                        height: 1.5,             // 줄간격
                      ),
                      textAlign: TextAlign.center, // 가운데 정렬
                    ),
                    SizedBox(height: 24),
                    
                    // 추가 안내 사항
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],                // 연한 파란색 배경
                        borderRadius: BorderRadius.circular(12), // 둥근 모서리
                        border: Border.all(color: Colors.blue[200]!), // 파란색 테두리
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 20), // 정보 아이콘
                              SizedBox(width: 8),
                              Text(
                                '안내사항',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700], // 진한 파란색
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• 이메일이 오지 않는다면 스팸함을 확인해주세요\n• 링크는 24시간 동안 유효합니다\n• 새 비밀번호 설정 후 앱에서 로그인해주세요',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700], // 진한 파란색
                              height: 1.4,              // 줄간격
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: 50),
        
        // ===== 확인 및 로그인으로 이동 버튼 =====
        ElevatedButton(
          onPressed: () => Navigator.pop(context), // 로그인 화면으로 돌아가기
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple, // 보라색 배경
            foregroundColor: Colors.white,      // 흰색 텍스트
            padding: EdgeInsets.symmetric(vertical: 16), // 상하 16px 패딩
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // 둥근 모서리
            ),
            elevation: 0, // 그림자 제거 (플랫 디자인)
          ),
          child: Text(
            '로그인 화면으로 돌아가기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // ===== 재발송 버튼 (보조 버튼) =====
        TextButton(
          onPressed: () {
            // 재발송을 위해 폼 화면으로 돌아가기
            setState(() {
              _emailSent = false; // 폼 화면으로 전환
            });
          },
          child: Text(
            '다시 발송하기',
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}