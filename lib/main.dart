import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'services/firebase_session_service.dart';
import 'services/storage_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await FirebaseSessionService.configure();
  runApp(TanyaUmrahRoot(auth: AuthProvider()));
}

class TanyaUmrahRoot extends StatelessWidget {
  final AuthProvider auth;
  const TanyaUmrahRoot({super.key, required this.auth});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => auth..initialize()),
      ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
        create: (_) => ChatProvider(),
        update: (_, auth, chat) => chat!..setAccount(auth.accountId),
      ),
    ],
    child: const TanyaUmrahApp(),
  );
}

class TanyaUmrahApp extends StatefulWidget {
  const TanyaUmrahApp({super.key});

  @override
  State<TanyaUmrahApp> createState() => _TanyaUmrahAppState();
}

class _TanyaUmrahAppState extends State<TanyaUmrahApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn && !auth.isInitializing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !auth.isLoggedIn) {
          _navigatorKey.currentState?.popUntil((route) => route.isFirst);
        }
      });
    }
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: auth.isInitializing
          ? const SplashScreen()
          : auth.isLoggedIn
          ? const MainNavigationScreen()
          : const LoginScreen(),
    );
  }
}
