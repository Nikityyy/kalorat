import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:kalorat/services/health_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockHealth extends Mock implements Health {}

void main() {
  setUpAll(() {
    registerFallbackValue(HealthDataType.WEIGHT);
    registerFallbackValue(HealthDataUnit.KILOGRAM);
    registerFallbackValue(DateTime(2000));
  });

  test('health sync writes weight in kilograms at the selected time', () async {
    final health = _MockHealth();
    final date = DateTime(2026, 7, 10, 7, 30);
    when(() => health.configure()).thenAnswer((_) async {});
    when(
      () => health.writeHealthData(
        value: any(named: 'value'),
        type: any(named: 'type'),
        startTime: any(named: 'startTime'),
        endTime: any(named: 'endTime'),
        unit: any(named: 'unit'),
      ),
    ).thenAnswer((_) async => true);

    final result = await HealthService(health: health).writeWeight(72.5, date);

    expect(result, isTrue);
    verify(
      () => health.writeHealthData(
        value: 72.5,
        type: HealthDataType.WEIGHT,
        startTime: date,
        endTime: date,
        unit: HealthDataUnit.KILOGRAM,
      ),
    ).called(1);
  });
}
