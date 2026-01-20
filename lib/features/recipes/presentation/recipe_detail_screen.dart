import 'package:cheat_days/features/auth/repository/auth_repository.dart';
import 'package:cheat_days/features/records/data/meal_record_repository.dart';
import 'package:cheat_days/features/records/domain/meal_record.dart';
import 'package:cheat_days/features/recipes/domain/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.name,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              background: Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) =>
                        Container(color: Colors.grey[300]),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info
                  Row(
                    children: [
                      _MetaChip(
                        icon: Icons.timer,
                        label: '${recipe.timeMinutes}分',
                      ),
                      const SizedBox(width: 12),
                      _MetaChip(
                        icon: Icons.currency_yen,
                        label: '約${recipe.costYen}円',
                      ),
                      const SizedBox(width: 12),
                      _MetaChip(
                        icon: Icons.local_fire_department,
                        label: '${recipe.calories ?? "-"}kcal',
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Ingredients
                  const Text(
                    "材料",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...recipe.ingredients.map(
                    (d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(d.name, style: const TextStyle(fontSize: 16)),
                          Text(
                            "${d.amount}${d.unit}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  // Steps
                  const Text(
                    "作り方",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recipe.steps.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recipe.steps[index],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final user =
                            ref.read(authRepositoryProvider).currentUser;
                        if (user != null) {
                          final record = MealRecord(
                            id: const Uuid().v4(),
                            recipeId: recipe.id,
                            recipeName: recipe.name,
                            imageUrl: recipe.imageUrl,
                            mealType: 'dinner',
                            date: DateTime.now(),
                            createdAt: DateTime.now(),
                          );

                          await ref
                              .read(mealRecordRepositoryProvider)
                              .addRecord(user.uid, record);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ごはんの記録に追加しました！')),
                            );
                            Navigator.pop(context);
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ログインが必要です')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("これ作った！"),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
