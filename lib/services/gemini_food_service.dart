import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiFoodService {

  static const apiKey =
      'AIzaSyCMtiDE6slZ7qoZfGdl1ETBbO1KAu3-hDw';

  static Future<Map<String, dynamic>>
  analyzeFood(
      File imageFile,
      ) async {

    try {

      final model =
      GenerativeModel(
        model: 'gemini-2.0-flash-lite',
        apiKey: apiKey,
      );

      final imageBytes =
      await imageFile.readAsBytes();

      final prompt = '''
Analyze this food image.

Return ONLY valid JSON.

Format:

{
  "type": "Fruit / Vegetable / Meal / Drink",
  "name": "Food Name",
  "calories": "value",
  "protein": "value",
  "carbs": "value",
  "fat": "value",
  "healthScore": "value",
  "benefits": "short health benefit"
}

Do not add markdown.
Do not add explanation.
''';

      final response =
      await model.generateContent([

        Content.multi([

          TextPart(prompt),

          DataPart(
            'image/jpeg',
            imageBytes,
          ),
        ]),
      ]);

      final text =
          response.text ?? '';

      final cleaned =
      text
          .replaceAll(
        '```json',
        '',
      )
          .replaceAll(
        '```',
        '',
      )
          .trim();

      final result =
      cleaned
          .replaceAll('\n', '');

      return {

        'raw': result,
      };

    } catch (e) {

      return {

        'raw': '''
{
"type":"Unknown",
"name":"Unknown Food",
"calories":"0",
"protein":"0",
"carbs":"0",
"fat":"0",
"healthScore":"0/10",
"benefits":"Unable to analyze"
}
'''
      };
    }
  }
}


