import 'dart:async';
import 'package:cheat_days/core/constants/app_constants.dart';
import 'package:cheat_days/features/agent/domain/messie_action.dart';
import 'package:cheat_days/features/agent/presentation/messie_agent_provider.dart';
import 'package:cheat_days/features/recipes/domain/recipe.dart';
import 'package:cheat_days/features/recipes/presentation/daily_suggestion_provider.dart';
import 'package:cheat_days/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isChatting = false;
  bool _showSideDish = false;

  // Static variable to track if initial slide-in has happened in this app session
  static bool _hasAnimatedEntry = false;
  Timer? _swayTimer;

  // Messie Animation Controllers
  late AnimationController _messieSlideController;
  late AnimationController _messieSwayController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _swayAnimation;

  @override
  void initState() {
    super.initState();
    // Slide-in animation (plays once)
    _messieSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _messieSlideController,
        curve: Curves.easeOutBack,
      ),
    );

    // Only animate on first launch of this screen in the session
    if (!_hasAnimatedEntry) {
      _messieSlideController.forward();
      _hasAnimatedEntry = true;
    } else {
      _messieSlideController.value = 1.0;
    }

    // Sway animation (loops)
    _messieSwayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _swayAnimation = Tween<double>(begin: -0.03, end: 0.03).animate(
      CurvedAnimation(parent: _messieSwayController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messieSlideController.dispose();
    _messieSwayController.dispose();
    _swayTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isChatting) return;

    setState(() {
      _isChatting = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      // Use Messie Agent for processing
      await ref.read(messieAgentProvider.notifier).processUserMessage(message);

      if (mounted) {
        _scrollToBottom();
        // Check for actions that update UI
        _handleAgentActions();
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

  void _handleAgentActions() {
    final agentState = ref.read(messieAgentProvider);

    // Show feedback for actions
    for (final action in agentState.recentActions) {
      switch (action.type) {
        case MessieActionType.addToShopping:
          final items = action.data['items'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🗭 買い物リストに追加: ${items.join(", ")}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          break;
        case MessieActionType.recordMeal:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 料理を記録しました'),
              duration: Duration(seconds: 2),
            ),
          );
          break;
        case MessieActionType.changeSuggestion:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🍽️ メニューを変更したっシー'),
              duration: Duration(seconds: 2),
            ),
          );
          break;
        case MessieActionType.adjustRecipe:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✨ レシピを調整したっシー'),
              duration: Duration(seconds: 2),
            ),
          );
          break;
        case MessieActionType.updateFridge:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🧊 冷蔵庫の中身を更新したっシー'),
              duration: Duration(seconds: 2),
            ),
          );
          break;
        default:
          break;
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
      // Sync daily suggestion with agent state
      if (next.value != null) {
        ref
            .read(messieAgentProvider.notifier)
            .syncWithDailySuggestion(next.value!);
      }

      // Reset side dish toggle if recipe changes
      if (previous?.value?.recipe?.id != next.value?.recipe?.id) {
        setState(() {
          _showSideDish = false;
        });
      }
    });

    // Listen to Messie's last message to trigger sway animation
    ref.listen(messieAgentProvider.select((s) => s.lastMessage), (prev, next) {
      if (next != null) {
        _messieSwayController.repeat(reverse: true);
        _swayTimer?.cancel();
        _swayTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            _messieSwayController.stop();
            _messieSwayController.animateTo(0);
          }
        });
      }
    });

    final suggestionAsync = ref.watch(dailySuggestionProvider);
    final messieState = ref.watch(messieAgentProvider);

    return Scaffold(
      body: SafeArea(
        child: suggestionAsync.when(
          data: (state) {
            // Verify we have a recipe from either source
            final recipe = messieState.currentSuggestion ?? state.recipe;

            if (recipe == null) {
              return _buildEmptyState();
            }
            // Ensure synchronization if Messie state is empty but Daily is not
            if (messieState.currentSuggestion == null && state.recipe != null) {
              Future.microtask(
                () => ref
                    .read(messieAgentProvider.notifier)
                    .syncWithDailySuggestion(state),
              );
            }

            return _buildContent(context, recipe, messieState);
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

  Widget _buildContent(
    BuildContext context,
    Recipe recipe,
    MessieAgentState agentState,
  ) {
    final comment = agentState.lastMessage;
    final sideDish = agentState.sideDish;
    final chatHistory = agentState.chatHistory;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Sticky Header
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.white,
                elevation: 1,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    errorBuilder: (_, __, ___) => const Text("🦕"),
                  ),
                ),
                title: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日の献立',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Text(
                        recipe.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
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
                      child: Column(
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
                            height: 280,
                            child: _RecipeCard(recipe: recipe),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Side Dish Card (if shown)
                  if (_showSideDish && sideDish != null) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      RecipeDetailScreen(recipe: sideDish),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 8,
                                left: 4,
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    "副菜",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "(${sideDish.name})",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 180,
                              child: _RecipeCard(recipe: sideDish),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Quick Action Chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ActionChip(
                          label: '時短',
                          onTap: () => ref.refresh(dailySuggestionProvider),
                        ),
                        _ActionChip(
                          label: '節約',
                          onTap: () => ref.refresh(dailySuggestionProvider),
                        ),
                        if (!_showSideDish && sideDish != null)
                          _ActionChip(
                            label: 'もう一品',
                            isPrimary: true,
                            onTap: () => setState(() => _showSideDish = true),
                          ),
                        _ActionChip(
                          label: '別の主菜',
                          onTap: () => ref.refresh(dailySuggestionProvider),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Chat Section Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          'メッシーとの会話',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        if (chatHistory.isNotEmpty)
                          GestureDetector(
                            onTap:
                                () => _scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_upward,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'トップへ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Chat History
                  if (chatHistory.isEmpty && comment != null)
                    _buildLargeMessageBubble(
                      ChatMessage(text: comment, isUser: false),
                    ),

                  ...chatHistory.map((msg) => _buildLargeMessageBubble(msg)),

                  // Bottom padding
                  const SizedBox(height: 20),
                ]),
              ),
            ],
          ),
        ),

        // Sticky Input Area
        Container(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'メッシーに話しかける...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isChatting,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _isChatting ? null : _sendMessage,
                    icon:
                        _isChatting
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLargeMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            SlideTransition(
              position: _slideAnimation,
              child: AnimatedBuilder(
                animation: _swayAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _swayAnimation.value,
                    child: child,
                  );
                },
                child: Image.asset(
                  'assets/images/messie.png',
                  width: 70,
                  height: 70,
                  errorBuilder:
                      (_, __, ___) =>
                          const Text("🦕", style: TextStyle(fontSize: 40)),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.green[100] : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  topLeft:
                      message.isUser ? const Radius.circular(16) : Radius.zero,
                  topRight:
                      message.isUser ? Radius.zero : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final isAiGenerated = recipe.tags.contains('AI考案');

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
                          (context, error, stackTrace) => _buildPlaceholder(),
                    )
                    : _buildPlaceholder(isAiGenerated: isAiGenerated),
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
                if (isAiGenerated)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AI考案',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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

  Widget _buildPlaceholder({bool isAiGenerated = false}) {
    if (isAiGenerated) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.auto_awesome, size: 80, color: Colors.white24),
        ),
      );
    }
    return Container(
      color: Colors.orange[100],
      child: const Icon(Icons.restaurant, size: 80, color: Colors.orange),
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
