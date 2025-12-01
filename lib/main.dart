import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: CheatDaysApp(),
    ),
  );
}

class CheatDaysApp extends StatelessWidget {
  const CheatDaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'チートデイズ ~目で食べる~',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
