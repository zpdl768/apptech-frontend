// ===== AppTech 메인 엔트리 포인트 =====
// Flutter, Firebase, Provider, Google AdMob을 활용한 타이핑 캐시 적립 앱

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';    // Firebase 초기화
import 'package:provider/provider.dart';              // 상태 관리
import 'package:google_mobile_ads/google_mobile_ads.dart';  // AdMob 광고
import 'widgets/auth_wrapper.dart';                   // 인증 래퍼 위젯
import 'providers/auth_provider.dart';                // Firebase 인증 프로바이더
import 'providers/user_provider.dart';                // 사용자 데이터 프로바이더

/// AppTech 앱의 메인 엔트리 포인트
/// Firebase와 AdMob 초기화 후 Flutter 앱을 실행하는 비동기 메인 함수
/// 
/// 초기화 순서:
/// 1. Flutter 위젯 바인딩 초기화 → 2. Firebase 초기화 → 3. AdMob 초기화 → 4. 앱 실행
void main() async {
  // ===== Flutter 엔진 초기화 =====
  // 비동기 작업 전에 Flutter 위젯 바인딩을 초기화하여 안전한 플랫폼 채널 사용 보장
  WidgetsFlutterBinding.ensureInitialized();
  
  // ===== Firebase 초기화 =====
  // Firebase Authentication, Firestore 등 Firebase 서비스 초기화
  await Firebase.initializeApp();
  
  // ===== Google AdMob 초기화 =====
  // 광고 수익화를 위한 AdMob SDK 초기화
  await MobileAds.instance.initialize();
  
  // ===== Flutter 앱 실행 =====
  runApp(const MyApp());  // MyApp 위젯을 루트로 하는 Flutter 앱 시작
}

/// AppTech 앱의 루트 위젯
/// Provider 패턴으로 전역 상태 관리를 설정하고 MaterialApp으로 앱 테마와 초기 화면을 구성
/// AuthProvider와 UserProvider를 통해 인증 상태와 사용자 데이터를 앱 전체에서 공유
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ===== 앱 루트 위젯 빌드 메서드 =====
  
  /// 앱의 전체 구조를 정의하는 메인 빌드 메서드
  /// MultiProvider로 전역 상태 관리 설정 후 MaterialApp으로 앱 초기화
  /// Provider 패턴을 통해 인증과 사용자 데이터를 앱 전체에서 공유 가능하도록 구성
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // ===== 전역 상태 관리 프로바이더 설정 =====
      providers: [
        // Firebase 인증 상태 관리 프로바이더
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // 사용자 데이터(캐시, 타이핑 현황) 관리 프로바이더  
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      
      // ===== MaterialApp 앱 설정 =====
      child: MaterialApp(
        title: 'AppTech',                          // 앱 이름 (작업 관리자, 앱 전환기에서 표시)
        
        // ===== 앱 테마 설정 =====
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,        // 메인 테마 색상: 딥퍼플
        ),
        
        // ===== 초기 화면 설정 =====
        home: AuthWrapper(),                      // 인증 상태에 따른 화면 라우팅을 담당하는 래퍼 위젯
      ),
    );
  }
}






// ===== 사용하지 않는 Flutter 템플릿 코드 =====
// 아래 주석 처리된 코드는 Flutter 프로젝트 생성 시 기본으로 제공되는 템플릿 코드입니다.
// AppTech 앱에서는 사용하지 않지만, 참고용으로 보존되어 있습니다.
// 실제 배포 시에는 이 코드 블록을 제거하는 것이 좋습니다.

/*
// Flutter 기본 템플릿 - Counter 앱
// 버튼을 누를 때마다 숫자가 증가하는 간단한 예제 앱
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
*/




