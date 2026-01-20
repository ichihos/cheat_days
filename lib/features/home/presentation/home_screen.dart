import 'package:cheat_days/core/constants/app_constants.dart';
import 'package:cheat_days/features/home/presentation/messie_widget.dart';
import 'package:cheat_days/features/recipes/domain/recipe.dart';
import 'package:cheat_days/features/recipes/presentation/daily_suggestion_provider.dart';
import 'package:cheat_days/features/recipes/presentation/json_import_screen.dart';
import 'package:cheat_days/features/recipes/presentation/recipe_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestionAsync = ref.watch(dailySuggestionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('献立提案'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JsonImportScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: suggestionAsync.when(
          data: (state) {
            final recipe = state.recipe;
            final comment = state.messieComment;

            if (recipe == null) {
              return const Center(child: Text("レシピが見つかりません"));
            }
            return Stack(
              children: [
                // Main Content
                Column(
                  children: [
                    const SizedBox(height: 20),
                    // Recipe Card (Top Half)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                        },
                        child: _RecipeCard(recipe: recipe),
                      ),
                    ),

                    const Spacer(),

                    // Messie Area
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: MessieWidget(
                        comment:
                            comment ??
                            "鶏もも肉そろそろ使い切りたい${AppConstants.messieSuffix}。\n${recipe.name}どう${AppConstants.messieSuffix}？",
                      ),
                    ),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // Reject logic
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                            ),
                            child: const Text('揚げ物ヤダ'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Force refresh suggestion
                              ref.refresh(dailySuggestionProvider);
                            },
                            child: const Text('別の提案'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.network(
              recipe.imageUrl,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  recipe.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${recipe.timeMinutes}分'),
                    const SizedBox(width: 16),
                    Icon(Icons.currency_yen, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('約${recipe.costYen}円'),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "↓ スワイプでレシピ",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
