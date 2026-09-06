import 'package:flutter_test/flutter_test.dart';
import 'package:gymrat/features/nutrition/data/open_food_facts_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('looks up global EAN data and maps nutrition per 100 grams', () async {
    late Uri requestedUri;
    final client = OpenFoodFactsClient(
      client: MockClient((request) async {
        requestedUri = request.url;
        expect(request.headers['User-Agent'], contains('getgymrat.com'));
        return http.Response('''
          {
            "product": {
              "product_name": "Test yoghurt",
              "brands": "Test brand",
              "serving_quantity": 150,
              "nutriments": {
                "energy-kcal_100g": 64,
                "proteins_100g": 9.7,
                "carbohydrates_100g": 4.1,
                "fat_100g": 0.2
              }
            }
          }
        ''', 200);
      }),
    );

    final product = await client.lookup(
      '7310865004703',
      languageCode: 'sv',
      countryCode: 'SE',
    );

    expect(requestedUri.host, 'world.openfoodfacts.org');
    expect(requestedUri.path, '/api/v3/product/7310865004703');
    expect(requestedUri.queryParameters['lc'], 'sv');
    expect(requestedUri.queryParameters['cc'], 'se');
    expect(product?.name, 'Test yoghurt');
    expect(product?.servingGrams, 150);
    final serving = product!.nutritionForGrams(150);
    expect(serving.calories, 96);
    expect(serving.proteinGrams, closeTo(14.55, .001));
    client.close();
  });

  test('returns null for missing, malformed and incomplete products', () async {
    final missing = OpenFoodFactsClient(
      client: MockClient((_) async => http.Response('{}', 404)),
    );
    expect(await missing.lookup('7310865004703'), isNull);
    expect(await missing.lookup('not-a-code'), isNull);
    missing.close();

    final incomplete = OpenFoodFactsClient(
      client: MockClient(
        (_) async => http.Response('''
        {"product":{"product_name":"Unknown","nutriments":{}}}
      ''', 200),
      ),
    );
    expect(await incomplete.lookup('7310865004703'), isNull);
    incomplete.close();
  });

  test('throws a typed failure for an unavailable product service', () async {
    final client = OpenFoodFactsClient(
      client: MockClient((_) async => http.Response('unavailable', 503)),
    );

    expect(
      () => client.lookup('7310865004703'),
      throwsA(isA<FoodProductLookupException>()),
    );
    client.close();
  });
}
