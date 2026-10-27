import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kalorat/services/barcode/product_lookup_service.dart';

class _MemoryCache implements ProductCache {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String code) async => values[code];

  @override
  Future<void> write(String code, String value) async => values[code] = value;
}

String _found(String name, {Map<String, Object>? nutriments}) => jsonEncode({
  'code': '5000112674453',
  'status': 1,
  'status_verbose': 'product found',
  'product': {
    'product_name': name,
    'quantity': '330 ml',
    'serving_quantity': 330,
    'nutriments':
        nutriments ??
        {
          'energy-kcal_100g': 33,
          'proteins_100g': 0,
          'carbohydrates_100g': 7.9,
          'fat_100g': 0,
        },
  },
});

final _notFound = jsonEncode({
  'status': 0,
  'status_verbose': 'product not found',
});

void main() {
  test('a known product is found, asked for with only the code', () async {
    final requests = <Uri>[];
    final service = ProductLookupService(
      cache: _MemoryCache(),
      client: MockClient((request) async {
        requests.add(request.url);
        return http.Response(_found('Sprite'), 200);
      }),
    );

    final result = await service.lookup('5000112674453');

    expect(result.status, ProductLookupStatus.found);
    expect(result.product!.name, 'Sprite');
    expect(requests.single.host, 'world.openfoodfacts.org');
    expect(requests.single.path, '/api/v2/product/5000112674453');
    expect(requests.single.queryParameters.keys, ['fields']);
  });

  test('unknown codes, by 404 or by status 0, are not found', () async {
    for (final response in [
      http.Response(_notFound, 404),
      http.Response(_notFound, 200),
    ]) {
      final service = ProductLookupService(
        cache: _MemoryCache(),
        client: MockClient((_) async => response),
      );
      expect(
        (await service.lookup('5000112674453')).status,
        ProductLookupStatus.notFound,
      );
    }
  });

  test('a product without nutrition says so and keeps its name', () async {
    final service = ProductLookupService(
      cache: _MemoryCache(),
      client: MockClient(
        (_) async => http.Response(
          _found('Mystery', nutriments: {'energy-kcal_100g': 100}),
          200,
        ),
      ),
    );

    final result = await service.lookup('5000112674453');

    expect(result.status, ProductLookupStatus.noNutrition);
    expect(result.product!.name, 'Mystery');
  });

  test('network and server errors fail and are not cached', () async {
    final cache = _MemoryCache();
    var calls = 0;
    final service = ProductLookupService(
      cache: cache,
      client: MockClient((_) async {
        calls++;
        if (calls == 1) throw http.ClientException('offline');
        return http.Response('busy', 503);
      }),
    );

    expect(
      (await service.lookup('5000112674453')).status,
      ProductLookupStatus.failed,
    );
    expect(
      (await service.lookup('5000112674453')).status,
      ProductLookupStatus.failed,
    );
    expect(cache.values, isEmpty);
  });

  test('a UPC-A code also finds its EAN-13 spelling', () async {
    final service = ProductLookupService(
      cache: _MemoryCache(),
      client: MockClient(
        (request) async => request.url.path.endsWith('/0036000291452')
            ? http.Response(_found('Gum'), 200)
            : http.Response(_notFound, 404),
      ),
    );

    final result = await service.lookup('036000291452', format: 'UPCA');

    expect(result.status, ProductLookupStatus.found);
    expect(result.product!.name, 'Gum');
  });

  test(
    'found products come from the cache, unknown codes only briefly',
    () async {
      final cache = _MemoryCache();
      var now = DateTime(2026, 10, 18, 12);
      var calls = 0;
      var known = false;
      final service = ProductLookupService(
        cache: cache,
        now: () => now,
        client: MockClient((_) async {
          calls++;
          return known
              ? http.Response(_found('Sprite'), 200)
              : http.Response(_notFound, 404);
        }),
      );

      expect(
        (await service.lookup('5000112674453')).status,
        ProductLookupStatus.notFound,
      );
      known = true;
      now = now.add(const Duration(minutes: 30));
      expect(
        (await service.lookup('5000112674453')).status,
        ProductLookupStatus.notFound,
      );
      expect(calls, 1);

      now = now.add(const Duration(hours: 1));
      expect(
        (await service.lookup('5000112674453')).status,
        ProductLookupStatus.found,
      );
      expect(calls, 2);

      now = now.add(const Duration(days: 20));
      final cached = await service.lookup('5000112674453');
      expect(cached.status, ProductLookupStatus.found);
      expect(cached.product!.name, 'Sprite');
      expect(calls, 2);
    },
  );

  group('search', () {
    // A Search-a-licious answer: flat hits, brands as tags.
    final hits = jsonEncode({
      'hits': [
        {
          'code': '3017620422003',
          'product_name': 'Nutella',
          'product_name_de': 'Nutella Nuss-Nougat-Creme',
          'brands': ['en:ferrero'],
          'quantity': '400 g',
          'nutriments': {
            'energy-kcal_100g': 539,
            'proteins_100g': 6.3,
            'carbohydrates_100g': 57.5,
            'fat_100g': 30.9,
          },
        },
        {
          'code': '4000000000001',
          'product_name': 'Nutella ohne Werte',
          'brands': 'Ferrero',
        },
        {'product_name': 'Ohne Code'},
      ],
      'count': 3,
      'page': 1,
      'page_size': 20,
      'page_count': 1,
      'took': 12,
      'timed_out': false,
      'is_count_exact': true,
    });

    test(
      'asks the search service once and keeps products with nutrition',
      () async {
        final requests = <Uri>[];
        final cache = _MemoryCache();
        final service = ProductLookupService(
          cache: cache,
          client: MockClient((request) async {
            requests.add(request.url);
            return http.Response(hits, 200);
          }),
        );

        final found = await service.search(' nutella ', language: 'de');

        expect(requests.single.host, 'search.openfoodfacts.org');
        expect(requests.single.path, '/search');
        expect(requests.single.queryParameters['q'], 'nutella');
        expect(requests.single.queryParameters['langs'], 'de,en');
        expect(found!.map((p) => p.name), ['Nutella Nuss-Nougat-Creme']);
        expect(found.single.brand, 'Ferrero');
        expect(found.single.caloriesPer100, 539);
        // Picked from the results, it opens like a scanned product, offline too.
        expect(cache.values.keys, ['3017620422003']);

        // The same search again is answered from memory.
        await service.search('Nutella', language: 'de');
        expect(requests, hasLength(1));
      },
    );

    test('a failed search is null, a too short one empty', () async {
      final service = ProductLookupService(
        cache: _MemoryCache(),
        client: MockClient((_) async => http.Response('busy', 503)),
      );

      expect(await service.search('nutella'), isNull);
      expect(await service.search('n'), isEmpty);
    });

    test('brand tags read as names', () {
      expect(ProductLookupService.searchBrand(['en:dr-oetker']), 'Dr Oetker');
      expect(ProductLookupService.searchBrand('Ferrero'), 'Ferrero');
      expect(ProductLookupService.searchBrand(const []), isNull);
      expect(ProductLookupService.searchBrand(null), isNull);
    });
  });
}
