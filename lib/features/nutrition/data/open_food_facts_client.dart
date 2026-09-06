import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/food_product.dart';

class OpenFoodFactsClient {
  OpenFoodFactsClient({http.Client? client})
    : _client = client ?? http.Client();

  static const _host = 'world.openfoodfacts.org';
  static const _fields = <String>[
    'code',
    'product_name',
    'product_name_en',
    'brands',
    'image_front_small_url',
    'serving_quantity',
    'nutriments',
  ];

  final http.Client _client;

  Future<FoodProduct?> lookup(
    String barcode, {
    String languageCode = 'en',
    String? countryCode,
  }) async {
    final cleanCode = barcode.replaceAll(RegExp(r'\D'), '');
    if (cleanCode.length < 8 || cleanCode.length > 14) return null;
    final uri = Uri.https(_host, '/api/v3/product/$cleanCode', <String, String>{
      'fields': _fields.join(','),
      'lc': languageCode,
      if (countryCode != null && countryCode.isNotEmpty)
        'cc': countryCode.toLowerCase(),
    });
    final response = await _client
        .get(
          uri,
          headers: const <String, String>{
            'User-Agent': 'GymRat/1.0 (https://getgymrat.com)',
          },
        )
        .timeout(const Duration(seconds: 12));
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const FoodProductLookupException();
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    final productValue = decoded['product'];
    if (productValue is! Map) return null;
    final product = Map<String, dynamic>.from(productValue);
    final nutrimentsValue = product['nutriments'];
    if (nutrimentsValue is! Map) return null;
    final nutriments = Map<String, dynamic>.from(nutrimentsValue);
    final calories = _number(
      nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal'],
    );
    final protein = _number(nutriments['proteins_100g']);
    final carbohydrates = _number(nutriments['carbohydrates_100g']);
    final fat = _number(nutriments['fat_100g']);
    final name =
        _text(product['product_name']) ?? _text(product['product_name_en']);
    if (name == null ||
        calories == null ||
        protein == null ||
        carbohydrates == null ||
        fat == null) {
      return null;
    }
    return FoodProduct(
      barcode: cleanCode,
      name: name,
      brand: _text(product['brands']),
      caloriesPer100Grams: calories.clamp(0, 1000),
      proteinPer100Grams: protein.clamp(0, 100),
      carbohydratesPer100Grams: carbohydrates.clamp(0, 100),
      fatPer100Grams: fat.clamp(0, 100),
      servingGrams: _number(product['serving_quantity']),
      imageUrl: _text(product['image_front_small_url']),
    );
  }

  void close() => _client.close();

  static double? _number(Object? value) => switch (value) {
    num number => number.toDouble(),
    String text => double.tryParse(text.replaceAll(',', '.')),
    _ => null,
  };

  static String? _text(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }
}

class FoodProductLookupException implements Exception {
  const FoodProductLookupException();
}
