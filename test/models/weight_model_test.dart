import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/models/weight_model.dart';

void main() {
  group('WeightModel', () {
    group('constructor', () {
      test('creates valid WeightModel with required fields', () {
        final weight = WeightModel(date: DateTime(2026, 2, 6), weight: 75.5);

        expect(weight.date, DateTime(2026, 2, 6));
        expect(weight.weight, 75.5);
        expect(weight.note, isNull);
      });

      test('creates valid WeightModel with optional note', () {
        final weight = WeightModel(
          date: DateTime(2026, 2, 6),
          weight: 75.5,
          note: 'After workout',
        );

        expect(weight.note, 'After workout');
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        final weight = WeightModel(
          date: DateTime(2026, 2, 6, 8, 30),
          weight: 75.5,
          note: 'Morning weight',
        );

        final json = weight.toJson();

        expect(json['date'], '2026-02-06T08:30:00.000');
        expect(json['weight'], 75.5);
        expect(json['note'], 'Morning weight');
      });

      test('serializes null note', () {
        final weight = WeightModel(date: DateTime(2026, 2, 6), weight: 75.5);

        final json = weight.toJson();

        expect(json['note'], isNull);
      });
    });

    group('fromJson', () {
      test('deserializes from valid JSON', () {
        final json = {
          'date': '2026-02-06T08:30:00.000',
          'weight': 75.5,
          'note': 'Morning weight',
        };

        final weight = WeightModel.fromJson(json);

        expect(weight.date, DateTime(2026, 2, 6, 8, 30));
        expect(weight.weight, 75.5);
        expect(weight.note, 'Morning weight');
      });

      test('handles null weight with default 0', () {
        final json = {'date': '2026-02-06T08:30:00.000', 'weight': null};

        final weight = WeightModel.fromJson(json);

        expect(weight.weight, 0.0);
      });

      test('handles integer weight by converting to double', () {
        final json = {
          'date': '2026-02-06T08:30:00.000',
          'weight': 75, // int, not double
        };

        final weight = WeightModel.fromJson(json);

        expect(weight.weight, 75.0);
        expect(weight.weight, isA<double>());
      });

      test('handles missing note as null', () {
        final json = {'date': '2026-02-06T08:30:00.000', 'weight': 75.5};

        final weight = WeightModel.fromJson(json);

        expect(weight.note, isNull);
      });
    });

    group('roundtrip serialization', () {
      test('toJson -> fromJson produces equivalent object', () {
        final original = WeightModel(
          date: DateTime(2026, 2, 6, 8, 30, 45),
          weight: 75.5,
          note: 'Test note',
        );

        final json = original.toJson();
        final restored = WeightModel.fromJson(json);

        expect(restored.weight, original.weight);
        expect(restored.note, original.note);
      });

      test('roundtrip works with null note', () {
        final original = WeightModel(date: DateTime(2026, 2, 6), weight: 80.0);

        final json = original.toJson();
        final restored = WeightModel.fromJson(json);

        expect(restored.note, isNull);
      });
    });

    group('edge cases', () {
      test('handles very small weight values', () {
        final weight = WeightModel(date: DateTime(2026, 2, 6), weight: 0.1);

        expect(weight.weight, 0.1);
      });

      test('handles very large weight values', () {
        final weight = WeightModel(date: DateTime(2026, 2, 6), weight: 500.0);

        expect(weight.weight, 500.0);
      });

      test('handles empty note string', () {
        final weight = WeightModel(
          date: DateTime(2026, 2, 6),
          weight: 75.5,
          note: '',
        );

        expect(weight.note, '');
      });
    });
  });
}
