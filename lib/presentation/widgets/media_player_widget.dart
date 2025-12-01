import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/cheat_day.dart';

class MediaPlayerWidget extends StatefulWidget {
  final CheatDay cheatDay;
  final bool isActive;
  final bool isPaused;

  const MediaPlayerWidget({
    super.key,
    required this.cheatDay,
    required this.isActive,
    this.isPaused = false,
  });

  @override
  State<MediaPlayerWidget> createState() => _MediaPlayerWidgetState();
}

class _MediaPlayerWidgetState extends State<MediaPlayerWidget> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.cheatDay.isVideo) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(MediaPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // アクティブ状態が変わった場合
    if (widget.isActive != oldWidget.isActive) {
      if (widget.cheatDay.isVideo) {
        if (widget.isActive) {
          _videoController?.play();
        } else {
          _videoController?.pause();
        }
      }
    }

    // 一時停止状態が変わった場合
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.cheatDay.isVideo && _videoController != null) {
        if (widget.isPaused) {
          _videoController!.pause();
        } else if (widget.isActive) {
          _videoController!.play();
        }
      }
    }

    // 別のチートデイに変わった場合
    if (widget.cheatDay.id != oldWidget.cheatDay.id) {
      if (widget.cheatDay.isVideo) {
        _disposeVideo();
        _initializeVideo();
      }
    }
  }

  Future<void> _initializeVideo() async {
    try {
      if (widget.cheatDay.mediaPath.startsWith('http')) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.cheatDay.mediaPath),
        );
      } else {
        _videoController = VideoPlayerController.file(
          File(widget.cheatDay.mediaPath),
        );
      }

      await _videoController!.initialize();
      _videoController!.setLooping(true);

      if (widget.isActive && !widget.isPaused) {
        await _videoController!.play();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('動画の初期化エラー: $e');
    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cheatDay.isImage) {
      return _buildImagePlayer();
    } else {
      return _buildVideoPlayer();
    }
  }

  Widget _buildImagePlayer() {
    if (widget.cheatDay.mediaPath.startsWith('http')) {
      return Image.network(
        widget.cheatDay.mediaPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error_outline, size: 64, color: Colors.white),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      );
    } else {
      return Image.file(
        File(widget.cheatDay.mediaPath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error_outline, size: 64, color: Colors.white),
          );
        },
      );
    }
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized || _videoController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _videoController!.value.size.width,
        height: _videoController!.value.size.height,
        child: VideoPlayer(_videoController!),
      ),
    );
  }
}
