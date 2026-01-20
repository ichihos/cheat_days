import 'package:cloud_firestore/cloud_firestore.dart';

class DataSeeder {
  static Future<void> seedRecipes() async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('recipes').limit(1).get();

    // Only seed if empty
    if (snapshot.docs.isEmpty) {
      print("Seeding recipes...");

      final recipes = [
        {
          "name": "チキン南蛮",
          "imageUrl":
              "https://placehold.co/600x400/orange/white?text=Chicken+Nanban", // Placeholder
          "category": "main",
          "cuisine": "japanese",
          "timeMinutes": 30,
          "costYen": 500,
          "difficulty": 2,
          "seasons": ["spring", "summer", "fall", "winter"],
          "ingredients": [
            {"name": "鶏もも肉", "amount": 300, "unit": "g", "isMain": true},
            {"name": "卵", "amount": 2, "unit": "個", "isMain": false},
            {"name": "玉ねぎ", "amount": 0.5, "unit": "個", "isMain": false},
          ],
          "steps": [
            "鶏肉を一口大に切り、塩胡椒をふる",
            "溶き卵にくぐらせ、170度の油で揚げる",
            "甘酢タレに絡め、タルタルソースをかける",
          ],
          "tags": ["ガッツリ", "定番", "人気"],
          "createdAt": DateTime.now(),
        },
        {
          "name": "豚肉とキャベツの味噌炒め",
          "imageUrl":
              "https://placehold.co/600x400/orange/white?text=Miso+Pork",
          "category": "main",
          "cuisine": "japanese",
          "timeMinutes": 15,
          "costYen": 300,
          "difficulty": 1,
          "seasons": ["spring", "winter"],
          "ingredients": [
            {"name": "豚バラ肉", "amount": 200, "unit": "g", "isMain": true},
            {"name": "キャベツ", "amount": 0.25, "unit": "玉", "isMain": false},
            {"name": "味噌", "amount": 2, "unit": "大さじ", "isMain": false},
          ],
          "steps": [
            "豚肉とキャベツを一口大に切る",
            "フライパンで豚肉を炒め、色が変わったらキャベツを入れる",
            "味噌ダレを加えて炒め合わせる",
          ],
          "tags": ["時短", "節約", "ご飯が進む"],
          "createdAt": DateTime.now(),
        },
        // Add more if needed, but 2 is enough to test "switch suggestion" logic logic partially (if we fix the randomizer)
      ];

      for (var data in recipes) {
        await firestore.collection('recipes').add(data);
      }
      print("Seeding complete.");
    } else {
      print("Recipes already exist. Skipping seed.");
    }
  }
}
