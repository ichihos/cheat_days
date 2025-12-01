import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/cheat_day.dart';
import '../providers/auth_provider.dart';
import '../providers/firebase_providers.dart';
import '../providers/cheat_day_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  File? _mediaFile;
  MediaType? _mediaType;
  VideoPlayerController? _videoController;
  bool _isUploading = false;
  bool _hasRecipe = false;
  bool _hasRestaurant = false;

  @override
  void dispose() {
    _titleController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    try {
      final picker = ImagePicker();
      XFile? pickedFile;

      if (isVideo) {
        pickedFile = await picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 5),
        );
      } else {
        pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1920,
          imageQuality: 85,
        );
      }

      if (pickedFile != null) {
        setState(() {
          _mediaFile = File(pickedFile!.path);
          _mediaType = isVideo ? MediaType.video : MediaType.image;
        });

        if (isVideo) {
          // ビデオの長さをチェック
          _videoController = VideoPlayerController.file(_mediaFile!);
          await _videoController!.initialize();

          final duration = _videoController!.value.duration;
          if (duration.inSeconds > 5) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('動画は5秒以内にしてください')),
              );
            }
            setState(() {
              _mediaFile = null;
              _mediaType = null;
              _videoController?.dispose();
              _videoController = null;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    }
  }

  Future<void> _uploadMedia() async {
    if (!_formKey.currentState!.validate() || _mediaFile == null) {
      return;
    }

    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインしてください')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload media to Firebase Storage
      final firestoreService = ref.read(firestoreServiceProvider);
      final mediaUrl = await firestoreService.uploadImage(
        _mediaFile!,
        currentUser.uid,
      );

      // Create CheatDay
      final cheatDay = CheatDay(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'Unknown',
        userPhotoUrl: currentUser.photoURL,
        mediaType: _mediaType!,
        mediaPath: mediaUrl,
        title: _titleController.text,
        date: DateTime.now(),
        isPublic: true,
        hasRecipe: _hasRecipe,
        hasRestaurant: _hasRestaurant,
        videoDurationSeconds: _videoController?.value.duration.inSeconds,
        likedBy: [],
        likesCount: 0,
        commentsCount: 0,
        sharesCount: 0,
      );

      // Save to Firestore
      final repository = ref.read(firebaseCheatDayRepositoryProvider);
      await repository.addCheatDay(cheatDay);

      // Refresh the feed
      ref.invalidate(cheatDaysProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投稿しました！')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('アップロードエラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('投稿'),
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _uploadMedia,
            child: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('投稿', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // メディアプレビュー
              if (_mediaFile != null)
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _mediaType == MediaType.video
                        ? _videoController != null &&
                                _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              )
                            : const Center(child: CircularProgressIndicator())
                        : Image.file(
                            _mediaFile!,
                            fit: BoxFit.cover,
                          ),
                  ),
                )
              else
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_photo_alternate,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // メディア選択ボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickMedia(ImageSource.gallery, false),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('写真を選択'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickMedia(ImageSource.gallery, true),
                      icon: const Icon(Icons.videocam),
                      label: const Text('動画を選択'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // タイトル入力
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '料理名',
                  hintText: '例: 特盛り唐揚げ定食',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '料理名を入力してください';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // レシピ・お店フラグ
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '追加情報',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('レシピあり'),
                        subtitle: const Text('後でレシピ情報を登録できます'),
                        value: _hasRecipe,
                        onChanged: (value) {
                          setState(() {
                            _hasRecipe = value ?? false;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      CheckboxListTile(
                        title: const Text('お店情報あり'),
                        subtitle: const Text('後でお店情報を登録できます'),
                        value: _hasRestaurant,
                        onChanged: (value) {
                          setState(() {
                            _hasRestaurant = value ?? false;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
