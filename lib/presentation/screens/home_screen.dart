import 'package:flutter/material.dart';
import 'tiktok_feed_screen.dart';
import 'my_cheat_days_screen.dart';
import 'calendar_screen.dart';
import 'wishlist_screen.dart';
import 'upload_screen.dart';
import 'recipe_form_screen.dart';
import 'restaurant_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const TikTokFeedScreen(),
    const CalendarScreen(),
    const SizedBox(), // Placeholder for post button
    const WishlistScreen(),
    const MyCheatDaysScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      // Handle post button - show post modal or navigate to upload screen
      _showPostOptions();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_a_photo),
                title: const Text('写真・動画を投稿'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UploadScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.restaurant),
                title: const Text('レシピを登録'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RecipeFormScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.store),
                title: const Text('お店を登録'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RestaurantFormScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle),
            label: '目で食べる',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 40),
            label: '投稿',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: '保存リスト',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'マイページ',
          ),
        ],
      ),
    );
  }
}
