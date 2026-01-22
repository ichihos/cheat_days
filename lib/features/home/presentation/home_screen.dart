import 'package:cheat_days/core/constants/app_constants.dart';
import 'package:cheat_days/features/auth/data/user_repository.dart';
import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/home/data/ai_service.dart';
import 'package:cheat_days/features/pantry/data/pantry_repository.dart';
import 'package:cheat_days/features/recipes/domain/recipe.dart';
import 'package:cheat_days/features/recipes/presentation/daily_suggestion_provider.dart';
import 'package:cheat_days/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:cheat_days/features/records/data/meal_record_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isChatting = false;
  bool _showSideDish = false;
  final List<ChatMessage> _chatHistory = [];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isChatting) return;

    setState(() {
      _isChatting = true;
      _chatHistory.add(ChatMessage(text: message, isUser: true));
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final user = ref.read(authStateProvider).value;
      if (user != null) {
        final settings = await ref.read(userSettingsProvider.future);
        final pantry = await ref
            .read(pantryRepositoryProvider)
            .getPantryItems(user.uid);
        final recent = await ref
            .read(mealRecordRepositoryProvider)
            .getRecentRecords(user.uid);

        final response = await ref
            .read(aiServiceProvider)
            .chatWithMessie(
              message: message,
              settings: settings,
              pantryItems: pantry,
              recentMeals: recent,
            );

        if (mounted) {
          setState(() {
            _chatHistory.add(ChatMessage(text: response, isUser: false));
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラーが発生したっシー: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isChatting = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dailySuggestionProvider, (previous, next) {
      // Clear history if recipe changes
      if (previous?.value?.recipe?.id != next.value?.recipe?.id) {
        setState(() {
          _chatHistory.clear();
          _showSideDish = false;
        });
      }
    });

    final suggestionAsync = ref.watch(dailySuggestionProvider);

    return Scaffold(
      body: SafeArea(
        child: suggestionAsync.when(
          data: (state) {
            final recipe = state.recipe;

            if (recipe == null) {
              return _buildEmptyState();
            }
            return _buildContent(context, state);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (e, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'エラーが発生しました',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.refresh(dailySuggestionProvider),
                      child: const Text('再試行'),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/messie.png',
            width: 120,
            height: 120,
            errorBuilder:
                (_, __, ___) =>
                    const Text("🦕", style: TextStyle(fontSize: 80)),
          ),
          const SizedBox(height: 24),
          Text(
            "レシピが見つからない${AppConstants.messieSuffix}",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            "Adminからレシピを追加してね",
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DailySuggestionState state) {
    final recipe = state.recipe!;
    final comment = state.messieComment;

    return Column(
      children: [
        // Recipe Area (Scrollable)
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder:
                            (_, __, ___) => Text(
                              'Messie',
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '今日の献立',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Main Recipe Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                    child: Builder(
                      builder: (context) {
                        // Main tag
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8, left: 4),
                              child: Text(
                                "主菜",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              height: 300, // Fixed height for main card
                              child: _RecipeCard(recipe: recipe),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Side Dish Card (if shown)
                if (_showSideDish && state.sideDish != null) ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    RecipeDetailScreen(recipe: state.sideDish!),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, left: 4),
                            child: Row(
                              children: [
                                const Text(
                                  "副菜",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "(${state.sideDish!.name})",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            // Smaller card for side dish? Or same?
                            height: 200,
                            child: _RecipeCard(recipe: state.sideDish!),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Quick Action Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _ActionChip(
                        label: '時短',
                        onTap: () => ref.refresh(dailySuggestionProvider),
                      ),
                      _ActionChip(
                        label: '節約',
                        onTap: () => ref.refresh(dailySuggestionProvider),
                      ),
                      if (!_showSideDish && state.sideDish != null)
                        _ActionChip(
                          label: 'もう一品',
                          isPrimary: true, // Highlight this as important
                          onTap: () => setState(() => _showSideDish = true),
                        ),
                      _ActionChip(
                        label: '別の主菜',
                        onTap: () => ref.refresh(dailySuggestionProvider),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Chat Area
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              children: [
                // Chat List
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          _chatHistory.length + 1, // +1 for initial message
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // Initial Messie Message
                          return _buildMessageBubble(
                            ChatMessage(
                              text:
                                  comment ??
                                  "${recipe.name}はどう${AppConstants.messieSuffix}？\n${recipe.timeMinutes}分で作れる${AppConstants.messieSuffix}！",
                              isUser: false,
                            ),
                            true, // Show avatar for first message
                          );
                        }
                        final chatMsg = _chatHistory[index - 1];
                        return _buildMessageBubble(
                          chatMsg,
                          !chatMsg.isUser, // Show avatar only for Messie
                        );
                      },
                    ),
                  ),
                ),

                // Input Area
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'メッシーに話しかける...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          enabled: !_isChatting,
                        ),
                      ),
                      IconButton(
                        onPressed: _isChatting ? null : _sendMessage,
                        icon:
                            _isChatting
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Icon(
                                  Icons.send,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser && showAvatar) ...[
            Image.asset(
              'assets/images/messie.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Text("🦕"),
            ),
            const SizedBox(width: 8),
          ] else if (!message.isUser)
            const SizedBox(width: 40), // Spacer for alignment

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.green[100] : Colors.white,
                borderRadius: BorderRadius.circular(12).copyWith(
                  topLeft:
                      message.isUser
                          ? const Radius.circular(12)
                          : const Radius.circular(0),
                  topRight:
                      message.isUser
                          ? const Radius.circular(0)
                          : const Radius.circular(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(message.text, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child:
                recipe.imageUrl.isNotEmpty
                    ? Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            color: Colors.orange[100],
                            child: const Icon(
                              Icons.restaurant,
                              size: 80,
                              color: Colors.orange,
                            ),
                          ),
                    )
                    : Container(
                      color: Colors.orange[100],
                      child: const Icon(
                        Icons.restaurant,
                        size: 80,
                        color: Colors.orange,
                      ),
                    ),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.timer,
                      text: '${recipe.timeMinutes}分',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tap hint
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 14, color: Colors.white70),
                  SizedBox(width: 4),
                  Text(
                    'レシピを見る',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.white)),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionChip({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: isPrimary ? Colors.white : Colors.black87,
          fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor:
          isPrimary ? Theme.of(context).colorScheme.primary : Colors.grey[200],
      onPressed: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
