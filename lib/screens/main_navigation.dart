import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'calendar_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainNavigationScope extends InheritedWidget {
  final int currentIndex;
  final ValueChanged<int> onSwitchTab;
  final void Function(String query) onAskQuestion;

  const MainNavigationScope({
    super.key,
    required this.currentIndex,
    required this.onSwitchTab,
    required this.onAskQuestion,
    required super.child,
  });

  static MainNavigationScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainNavigationScope>();
  }

  @override
  bool updateShouldNotify(MainNavigationScope oldWidget) {
    return currentIndex != oldWidget.currentIndex;
  }
}

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _pages = const [
    HomeScreen(),
    ChatScreen(),
    CalendarScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _switchTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _currentIndex = index);
    }
  }

  void _askQuestion(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chat = Provider.of<ChatProvider>(context, listen: false);
    _switchTab(1);
    chat.sendMessage(query: clean, student: auth.currentStudent);
  }

  @override
  Widget build(BuildContext context) {
    final isStreaming = context.select<ChatProvider, bool>(
      (chat) => chat.isStreaming,
    );

    return MainNavigationScope(
      currentIndex: _currentIndex,
      onSwitchTab: _switchTab,
      onAskQuestion: _askQuestion,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              top: BorderSide(color: AppConstants.borderLight),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            backgroundColor: Colors.white,
            indicatorColor: AppConstants.primaryBlue.withValues(alpha: 0.12),
            elevation: 0,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: _switchTab,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: AppConstants.primaryBlue),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: isStreaming,
                  backgroundColor: AppConstants.accentGold,
                  smallSize: 8,
                  child: const Icon(Icons.forum_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: isStreaming,
                  backgroundColor: AppConstants.accentGold,
                  smallSize: 8,
                  child: const Icon(Icons.forum_rounded, color: AppConstants.primaryBlue),
                ),
                label: 'Tanya AI',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded, color: AppConstants.primaryBlue),
                label: 'Kalender',
              ),
              const NavigationDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history_rounded, color: AppConstants.primaryBlue),
                label: 'Riwayat',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded, color: AppConstants.primaryBlue),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
