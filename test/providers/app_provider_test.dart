import 'package:flutter_test/flutter_test.dart';
import 'package:kalorat/models/models.dart';
import 'package:kalorat/providers/app_provider.dart';
import 'package:kalorat/services/database_service.dart';

class _MemoryDatabase extends DatabaseService {
  final List<WeightModel> weights = [];

  @override
  List<WeightModel> getAllWeights() => List.of(weights);

  @override
  Future<void> saveWeight(WeightModel weight) async {
    weights.removeWhere(
      (item) =>
          item.date.year == weight.date.year &&
          item.date.month == weight.date.month &&
          item.date.day == weight.date.day,
    );
    weights.add(weight);
  }
}

void main() {
  test('AppProvider updates an existing weight entry', () async {
    final database = _MemoryDatabase();
    final previous = WeightModel(date: DateTime(2026, 7, 10), weight: 70);
    database.weights.add(previous);
    final provider = AppProvider(databaseService: database);

    await provider.updateWeight(
      previous,
      WeightModel(date: previous.date, weight: 69.5),
    );

    expect(database.weights.single.weight, 69.5);
  });
}
