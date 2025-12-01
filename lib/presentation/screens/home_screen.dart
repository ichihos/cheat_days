import 'package:flutter/material.dart';
import 'slideshow_screen.dart';
import 'my_cheat_days_screen.dart';
import 'calendar_screen.dart';
import 'memo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SlideshowScreen(),
    const MyCheatDaysScreen(),
    const CalendarScreen(),
    const MemoScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle),
            label: '目で食べる',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'マイ写真',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'メモ',
          ),
        ],
      ),
    );
  }
}
