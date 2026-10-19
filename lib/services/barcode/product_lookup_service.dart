import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../../utils/app_logger.dart';
import '../../utils/app_version.dart';
import 'food_product.dart';
import 'gtin.dart';

enum ProductLookupStatus {
  /// Found, with usable nutrition.
  found,

  /// Found, but nutrition is missing or implausible.
  noNutrition,

  /// No product has this code.
  notFound,

  /// Offline, timed out or the service failed.
  failed,
}

class ProductLookupResult {
  final ProductLookupStatus status;
  final FoodProduct? product;

  const ProductLookupResult(this.status, [this.product]);
}

/// Remembers lookups so a product scanned again shows at once and works
/// offline. Unknown codes are remembered briefly: someone may add them.
abstract class ProductCache {
  Future<String?> read(String code);
  Future<void> write(String code, String value);
}

class HiveProductCache implements ProductCache {
  static const boxName = 'products_box';
  Box<String>? _box;

  Future<Box<String>> _open() async =>
      _box ??= await Hive.openBox<String>(boxName);

  @override
  Future<String?> read(String code) async => (await _open()).get(code);

  @override
  Future<void> write(String code, String value) async =>
      (await _open()).put(code, value);
}

/// Looks packaged food up by barcode in Open Food Facts (open data, ODbL).
/// Only the barcode number is sent.
class ProductLookupService {
  static const _host = 'world.openfoodfacts.org';
  static const _fields =
      'code,product_name,product_name_de,product_name_en,generic_name,'
      'generic_name_de,generic_name_en,brands,quantity,serving_quantity,'
      'serving_quantity_unit,serving_size,product_quantity,product_quantity_unit,nutriments';
  static const foundTtl = Duration(days: 30);
  static const notFoundTtl = Duration(hours: 1);
  static const timeout = Duration(seconds: 6);

  final http.Client _client;
  final ProductCache _cache;
  final DateTime Function() _now;

  ProductLookupService({
    http.Client? client,
    ProductCache? cache,
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _cache = cache ?? HiveProductCache(),
       _now = now ?? DateTime.now;

  /// Opens the product cache ahead of the first scan: opening it then
  /// would hold up the lookup that matters most.
  Future<void> prewarm() async {
    final cache = _cache;
    if (cache is HiveProductCache) {
      try {
        await cache._open();
      } catch (_) {}
    }
  }

  Future<ProductLookupResult> lookup(
    String code, {
    String? format,
    String language = 'en',
  }) async {
    final cached = await _readCache(code);
    if (cached != null) return cached;

    final candidates = lookupCandidates(code, format: format);
    // Alternative spellings of the same code are asked for in parallel; any
    // that Open Food Facts knows wins, even if another request failed.
    final responses = await Future.wait(
      candidates.map(
        (candidate) => _fetch(candidate, language)
            .timeout(timeout)
            .then<Object?>((product) => product, onError: (Object e) => e),
      ),
    );
    final product = responses.whereType<FoodProduct>().firstOrNull;
    if (product == null) {
      final error = responses.firstWhere((r) => r != null, orElse: () => null);
      if (error != null) {
        AppLogger.warning('ProductLookup', 'Lookup of $code failed: $error');
        return const ProductLookupResult(ProductLookupStatus.failed);
      }
    }
    final result = product == null
        ? const ProductLookupResult(ProductLookupStatus.notFound)
        : ProductLookupResult(
            product.hasNutrition
                ? ProductLookupStatus.found
                : ProductLookupStatus.noNutrition,
            product,
          );
    await _writeCache(code, result);
    return result;
  }

  /// The product, or null when Open Food Facts does not know [code].
  /// Throws on network and server errors.
  Future<FoodProduct?> _fetch(String code, String language) async {
    final uri = Uri.https(_host, '/api/v2/product/$code', {'fields': _fields});
    // Browsers send their own User-Agent; a custom header would also cost a
    // CORS preflight round trip.
    final headers = kIsWeb
        ? const <String, String>{}
        : {
            'User-Agent':
                'Kalorat/${AppVersion.name} (https://nikity.is-a.dev)',
          };
    final response = await _client.get(uri, headers: headers);
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw http.ClientException('HTTP ${response.statusCode}', uri);
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map || body['status'] != 1 || body['product'] is! Map) {
      return null;
    }
    return FoodProduct.fromOpenFoodFacts(
      code,
      Map<String, dynamic>.from(body['product'] as Map),
      language: language,
    );
  }

  /// Raised when the way a product is read changes, so cached products are
  /// read again (2: drinks with a unit of g, see FoodProduct._isLiquid).
  static const _cacheVersion = 2;

  Future<ProductLookupResult?> _readCache(String code) async {
    try {
      final raw = await _cache.read(code);
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['v'] != _cacheVersion) return null;
      final at = DateTime.fromMillisecondsSinceEpoch(json['at'] as int);
      final product = json['product'] is Map
          ? FoodProduct.fromJson(Map<String, dynamic>.from(json['product']))
          : null;
      final ttl = product == null ? notFoundTtl : foundTtl;
      if (_now().difference(at) > ttl) return null;
      if (product == null) {
        return const ProductLookupResult(ProductLookupStatus.notFound);
      }
      return ProductLookupResult(
        product.hasNutrition
            ? ProductLookupStatus.found
            : ProductLookupStatus.noNutrition,
        product,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String code, ProductLookupResult result) async {
    try {
      await _cache.write(
        code,
        jsonEncode({
          'v': _cacheVersion,
          'at': _now().millisecondsSinceEpoch,
          'product': result.product?.toJson(),
        }),
      );
    } catch (_) {}
  }
}
