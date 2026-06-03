import 'dart:convert';
import 'dart:io';
import '../config/api_keys.dart';

import 'package:http/http.dart' as http;

class OpenAIFoodService {

  static const String apiKey =
      ApiKeys.groqApiKey;

  // MANUAL FOOD NAME ANALYSIS
  static Future<String> analyzeFoodName(
      String foodName,
      ) async {
    final response = await http.post(
      Uri.parse(
        'https://api.groq.com/openai/v1/chat/completions',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "llama-3.3-70b-versatile",
        "messages": [
          {
            "role": "system",
            "content":
            "You are a nutrition expert. Return only JSON."
          },
          {
            "role": "user",
            "content": """
Analyze this food:

$foodName

Return ONLY valid JSON.

{
  "name":"Food Name",
  "type":"Fruit / Vegetable / Meal / Drink / Snack / Dairy / Fast Food / Protein Food",
  "calories":"0",
  "protein":"0",
  "carbs":"0",
  "fat":"0",
  "healthScore":"0/10",
  "benefits":"Health benefits"
}
"""
          }
        ]
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }

    final data = jsonDecode(response.body);

    String result =
    data['choices'][0]['message']['content'];

    result = result
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    return result;
  }

  // IMAGE ANALYSIS (currently simulated)
  static Future<Map<String, dynamic>> analyzeFood(
    File imageFile,
  ) async {
    try {
      final response = await analyzeFoodName(
        'Apple',
      );

      return {
        'raw': response,
      };
    } catch (e) {
      return {
        'raw': '''
{
"name":"Unknown Food",
"calories":"0",
"protein":"0",
"carbs":"0",
"fat":"0",
"healthScore":"0/10"
}
'''
      };
    }
  }
}