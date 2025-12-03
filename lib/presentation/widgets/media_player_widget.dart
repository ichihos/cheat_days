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
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child:
          widget.cheatDay.isImage ? _buildImagePlayer() : _buildVideoPlayer(),
    );
  }

  Widget _buildImagePlayer() {
    final imageWidget =
        widget.cheatDay.mediaPath.startsWith('http')
            ? Image.network(
              widget.cheatDay.mediaPath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 64,
                          color: Colors.white38,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '画像を読み込めません',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFFFF6B35),
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                    ),
                  ),
                );
              },
            )
            : Image.file(
              File(widget.cheatDay.mediaPath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 64,
                          color: Colors.white38,
                        ),
                        SizedBox(height: 12),
                        Text(
                          '画像を読み込めません',
                          style: TextStyle(color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

    return imageWidget;
  }

  Widget _buildVideoPlayer() {
    if (!_isInitialized || _videoController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
        ),
      );
    }

    // 画面サイズ
    final screenSize = MediaQuery.of(context).size;
    final videoSize = _videoController!.value.size;

    // アスペクト比を計算して画面いっぱいに表示
    final screenAspect = screenSize.width / screenSize.height;
    final videoAspect = videoSize.width / videoSize.height;

    double scale;
    if (videoAspect > screenAspect) {
      // 動画が横長 → 高さに合わせてスケール
      scale = screenSize.height / videoSize.height;
    } else {
      // 動画が縦長 → 幅に合わせてスケール
      scale = screenSize.width / videoSize.width;
    }

    return ClipRect(
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: SizedBox(
          width: videoSize.width * scale,
          height: videoSize.height * scale,
          child: VideoPlayer(_videoController!),
        ),
      ),
    );
  }
}
