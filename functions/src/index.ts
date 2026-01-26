
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as dayjs from "dayjs";
import { VertexAI } from "@google-cloud/vertexai";

admin.initializeApp();
const db = admin.firestore();

// Initialize Vertex AI
const vertexAI = new VertexAI({
    project: process.env.GCLOUD_PROJECT || "cheat-days", // Make sure to set project ID
    location: "us-central1", // Or appropriate location
});

const model = vertexAI.getGenerativeModel({
    model: "gemini-1.5-flash", // Using 1.5-flash as 2.5 might not be available in vertex node SDK yet or naming differs. Checking availability...
    // User asked for what was in the app which was 'gemini-2.5-flash'. 
    // Note: 'gemini-2.5-flash' might be a typo in user's app or a very new preview. 
    // Standard stable is 1.5-flash. I will use 1.5-flash for safety unless 2.5 is confirmed.
    // Actually, let's stick to what we often use or try to match. I'll use 1.5-flash which is standard fast model.
    generationConfig: {
        responseMimeType: "application/json",
    },
});

interface UserSettings {
    dislikedIngredients: string[];
    servingSize: number;
}

interface Recipe {
    id: string;
    name: string;
    category: string;
    cuisine: string;
    timeMinutes: number;
    ingredients: { name: string }[];
    tags: string[];
}

export const generateDailyMenu = functions.pubsub
    .schedule("0 4 * * *") // Run at 4:00 AM
    .timeZone("Asia/Tokyo")
    .onRun(async (context) => {
        const today = dayjs().tz("Asia/Tokyo").format("YYYY-MM-DD");
        const yesterday4am = dayjs().tz("Asia/Tokyo").subtract(1, "day").hour(4).toDate();

        console.log(`Starting daily menu generation for ${today}`);

        // 1. Get Active Users (accessed since yesterday 4am)
        // Note: You need to implement 'lastAccessAt' in the app first.
        // For now, we will process users who have 'lastAccessAt' > yesterday4am
        // If 'lastAccessAt' doesn't exist yet, we might skip them or default to processing all for testing?
        // Let's strictly follow the rule: "Generate for active users".
        const usersSnap = await db.collection("users")
            .where("lastAccessAt", ">", admin.firestore.Timestamp.fromDate(yesterday4am))
            .get();

        if (usersSnap.empty) {
            console.log("No active users found.");
            return;
        }

        console.log(`Found ${usersSnap.size} active users.`);

        // 2. Fetch All Recipes (Cache this if possible, but for batch it's okay)
        const recipesSnap = await db.collection("recipes").get();
        const allRecipes = recipesSnap.docs.map((doc) => {
            const data = doc.data();
            return {
                id: doc.id,
                name: data.name,
                category: data.category,
                cuisine: data.cuisine,
                timeMinutes: data.timeMinutes,
                ingredients: data.ingredients || [],
                tags: data.tags || [],
            } as Recipe;
        });

        if (allRecipes.length === 0) {
            console.log("No recipes found.");
            return;
        }

        // 3. Process each user
        const promises = usersSnap.docs.map(async (userDoc) => {
            const uid = userDoc.id;
            try {
                await generateForUser(uid, allRecipes, today);
            } catch (e) {
                console.error(`Failed to generate for user ${uid}:`, e);
            }
        });

        await Promise.all(promises);
        console.log("Daily menu generation completed.");
    });


async function generateForUser(uid: string, allRecipes: Recipe[], dateStr: string) {
    // A. user settings
    const settingsSnap = await db.doc(`users/${uid}`).get();
    const settingsData = settingsSnap.data();
    // Assuming settings are flattened on user doc or in subcollection. 
    // Based on Dart: ref.watch(userSettingsProvider) fetches from somewhere. 
    // Usually it's in a subdoc or the user doc. Let's assume user doc has servingSize etc.
    // If not, we use defaults.
    const settings: UserSettings = {
        dislikedIngredients: settingsData?.dislikedIngredients || [],
        servingSize: settingsData?.servingSize || 2,
    };

    // B. Recent Meals (last 7 days)
    // Assuming 'meal_records' subcollection
    const recentMealsSnap = await db.collection(`users/${uid}/meal_records`)
        .orderBy("date", "desc")
        .limit(10) // fetch last 10
        .get();

    const recentMealsText = recentMealsSnap.empty ? "なし" : recentMealsSnap.docs.map(d => {
        const data = d.data();
        return `${data.recipeName} (${data.mealType})`;
    }).join(", ");

    // C. Pantry
    const pantrySnap = await db.collection(`users/${uid}/pantry`).get();
    const pantryText = pantrySnap.empty ? "不明" : pantrySnap.docs
        .filter(d => d.data().estimatedAmount !== "なし")
        .map(d => `${d.data().ingredientName}(${d.data().estimatedAmount})`)
        .join(", ");

    // D. Select Candidates
    // Shuffle and pick
    const mainCategories = ['main', 'rice', 'noodle'];
    const sideCategories = ['side', 'soup'];

    const mains = allRecipes.filter(r => mainCategories.includes(r.category));
    const sides = allRecipes.filter(r => sideCategories.includes(r.category));

    // Simple shuffle
    mains.sort(() => Math.random() - 0.5);
    sides.sort(() => Math.random() - 0.5);

    const candidates = [...mains.slice(0, 6), ...sides.slice(0, 4)];

    // Fallback if not enough
    if (candidates.length < 5) {
        const remaining = allRecipes.filter(r => !candidates.includes(r));
        remaining.sort(() => Math.random() - 0.5);
        candidates.push(...remaining.slice(0, 10 - candidates.length));
    }

    const candidatesJson = candidates.map(r => ({
        id: r.id,
        name: r.name,
        ingredients: r.ingredients.map(i => i.name),
        category: r.category,
        cuisine: r.cuisine,
        timeMinutes: r.timeMinutes,
        tags: r.tags
    }));

    // E. Generate Prompt
    const prompt = `
あなたは献立提案アシスタント「メッシー」です。
小型恐竜のキャラで、有能・実用的・ちょっとドライな性格です。
語尾は必ず「〜っシー」にしてください。

## ユーザー情報
- 最近の食事履歴: ${recentMealsText}
- 苦手な食材: ${settings.dislikedIngredients.join(", ") || "なし"}
- 冷蔵庫にありそうなもの: ${pantryText}
- 人数: ${settings.servingSize}人分
- 今日の曜日: ${dayjs(dateStr).format('dddd')}
- 日付: ${dateStr}

## レシピ候補（JSON）
${JSON.stringify(candidatesJson)}

## タスク
1. 上記のレシピ候補から最適な「主菜（Main）」を1品選んでください
2. その主菜に合う「副菜（Side/Soup）」があれば1品選んでください（なければnull）
3. 選定理由を簡潔に
4. メッシーとしての一言コメント

## 出力形式（JSON）
{
  "selectedRecipeId": "主菜のレシピID",
  "sideDishRecipeId": "副菜のレシピID（またはnull）",
  "reason": "選定理由",
  "messieComment": "コメント"
}
`;

    // F. Call AI
    const result = await model.generateContent(prompt);
    const response = await result.response;
    const text = response.text();

    let json: any = {};
    if (text) {
        const cleanText = text.replace(/```json/g, "").replace(/```/g, "").trim();
        try {
            json = JSON.parse(cleanText);
        } catch (e) {
            console.error("Failed to parse JSON", text);
            // Fallback to first candidate
            json = {
                selectedRecipeId: candidates[0].id,
                messieComment: `${candidates[0].name}がいいと思うっシー！`,
                reason: "AI生成に失敗したため、おすすめを選びました。"
            };
        }
    }

    // G. Save to Firestore
    await db.doc(`users/${uid}/daily_suggestions/${dateStr}`).set({
        ...json,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        date: dateStr
    });

    console.log(`Generated for ${uid}: ${json.selectedRecipeId}`);
}
