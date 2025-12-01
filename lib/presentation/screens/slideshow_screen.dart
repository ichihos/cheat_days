import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cheat_day_provider.dart';
import '../providers/slideshow_provider.dart';

class SlideshowScreen extends ConsumerWidget {
  const SlideshowScreen({super.key});

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cheatDaysAsync = ref.watch(cheatDaysProvider);
    final slideshowState = ref.watch(slideshowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('チートデイズ ~目で食べる~'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: cheatDaysAsync.when(
        data: (cheatDays) {
          if (cheatDays.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'まだチートデイの写真がありません',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'マイ写真から追加しましょう',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final currentCheatDay = cheatDays[slideshowState.currentIndex % cheatDays.length];

          return Column(
            children: [
              if (slideshowState.isPlaying)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.orange.shade100,
                  child: Column(
                    children: [
                      Text(
                        '残り時間: ${_formatTime(slideshowState.remainingSeconds)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressBar(
                        value: slideshowState.remainingSeconds /
                            (slideshowState.timerDurationMinutes * 60),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Image.file(
                        File(currentCheatDay.imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          currentCheatDay.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!slideshowState.isPlaying)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'タイマー設定',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _TimerButton(
                            minutes: 5,
                            isSelected: slideshowState.timerDurationMinutes == 5,
                            onTap: () {
                              ref.read(slideshowProvider.notifier).setTimerDuration(5);
                            },
                          ),
                          _TimerButton(
                            minutes: 10,
                            isSelected: slideshowState.timerDurationMinutes == 10,
                            onTap: () {
                              ref.read(slideshowProvider.notifier).setTimerDuration(10);
                            },
                          ),
                          _TimerButton(
                            minutes: 15,
                            isSelected: slideshowState.timerDurationMinutes == 15,
                            onTap: () {
                              ref.read(slideshowProvider.notifier).setTimerDuration(15);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(slideshowProvider.notifier).startSlideshow(
                                cheatDays.length,
                                slideshowState.timerDurationMinutes,
                              );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                        ),
                        child: const Text(
                          '目で食べる開始',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              if (slideshowState.isPlaying)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(slideshowProvider.notifier).stopSlideshow();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                    ),
                    child: const Text(
                      '停止',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラー: $error'),
        ),
      ),
    );
  }
}

class _TimerButton extends StatelessWidget {
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimerButton({
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey,
            width: 2,
          ),
        ),
        child: Text(
          '$minutes分',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class LinearProgressBar extends StatelessWidget {
  final double value;

  const LinearProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.grey.shade300,
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
      ),
    );
  }
}
