import 'dart:convert';

import 'package:http/http.dart'
as http;

class FoodAIService {

  static Future<Map<String, dynamic>>
  getFoodDetails(
      String food,
      ) async {

    try {

      final url =
      Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$food&search_simple=1&action=process&json=1',
      );

      final response =
      await http.get(url);

      if (response.statusCode == 200) {

        final data =
        jsonDecode(response.body);

        if (data['products'] != null &&
            data['products']
                .isNotEmpty) {

          final product =
          data['products'][0];

          final nutriments =
              product['nutriments'] ?? {};

          return {

            'name':
            product['product_name']
                ?.toString()
                .isNotEmpty ==
                true
                ? product['product_name']
                : food,

            'calories':
            nutriments[
            'energy-kcal_100g']
                ?.toString() ??
                '120',

            'protein':
            nutriments[
            'proteins_100g']
                ?.toString() ??
                '2',

            'carbs':
            nutriments[
            'carbohydrates_100g']
                ?.toString() ??
                '15',

            'fat':
            nutriments[
            'fat_100g']
                ?.toString() ??
                '1',
          };
        }
      }

      // FALLBACK VALUES

      return _fallbackNutrition(
        food,
      );

    } catch (e) {

      return _fallbackNutrition(
        food,
      );
    }
  }

  static Map<String, dynamic>
  _fallbackNutrition(
      String food,
      ) {

    final lower =
    food.toLowerCase();

    if (lower.contains('apple')) {

      return {

        'name': 'Apple',
        'calories': '52',
        'protein': '0.3',
        'carbs': '14',
        'fat': '0.2',
      };
    }

    if (lower.contains('banana')) {

      return {

        'name': 'Banana',
        'calories': '89',
        'protein': '1.1',
        'carbs': '23',
        'fat': '0.3',
      };
    }

    if (lower.contains('rice')) {

      return {

        'name': 'Rice',
        'calories': '130',
        'protein': '2.7',
        'carbs': '28',
        'fat': '0.3',
      };
    }

    if (lower.contains('pomegranate')) {

      return {

        'name': 'Pomegranate',
        'calories': '83',
        'protein': '1.7',
        'carbs': '19',
        'fat': '1.2',
      };
    }

    if (lower.contains('orange')) {

      return {

        'name': 'Orange',
        'calories': '47',
        'protein': '0.9',
        'carbs': '12',
        'fat': '0.1',
      };
    }

    return {

      'name': food,
      'calories': '120',
      'protein': '2',
      'carbs': '15',
      'fat': '1',
    };
  }
}