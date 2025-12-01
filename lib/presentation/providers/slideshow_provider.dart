import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SlideshowState {
  final int currentIndex;
  final bool isPlaying;
  final int timerDurationMinutes;
  final int remainingSeconds;

  SlideshowState({
    this.currentIndex = 0,
    this.isPlaying = false,
    this.timerDurationMinutes = 5,
    this.remainingSeconds = 0,
  });

  SlideshowState copyWith({
    int? currentIndex,
    bool? isPlaying,
    int? timerDurationMinutes,
    int? remainingSeconds,
  }) {
    return SlideshowState(
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      timerDurationMinutes: timerDurationMinutes ?? this.timerDurationMinutes,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

final slideshowProvider = StateNotifierProvider<SlideshowNotifier, SlideshowState>((ref) {
  return SlideshowNotifier();
});

class SlideshowNotifier extends StateNotifier<SlideshowState> {
  Timer? _slideTimer;
  Timer? _countdownTimer;

  SlideshowNotifier() : super(SlideshowState());

  void startSlideshow(int totalImages, int durationMinutes) {
    state = state.copyWith(
      isPlaying: true,
      timerDurationMinutes: durationMinutes,
      remainingSeconds: durationMinutes * 60,
    );

    _slideTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (state.currentIndex < totalImages - 1) {
        state = state.copyWith(currentIndex: state.currentIndex + 1);
      } else {
        state = state.copyWith(currentIndex: 0);
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        stopSlideshow();
      }
    });
  }

  void stopSlideshow() {
    _slideTimer?.cancel();
    _countdownTimer?.cancel();
    state = state.copyWith(
      isPlaying: false,
      currentIndex: 0,
      remainingSeconds: 0,
    );
  }

  void setTimerDuration(int minutes) {
    state = state.copyWith(timerDurationMinutes: minutes);
  }

  @override
  void dispose() {
    _slideTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
