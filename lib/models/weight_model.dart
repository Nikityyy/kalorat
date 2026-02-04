import 'package:hive/hive.dart';

part 'weight_model.g.dart';

@HiveType(typeId: 2)
class WeightModel extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double weight; // in kg

  @HiveField(2)
  String? note;

  WeightModel({required this.date, required this.weight, this.note});

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
    'note': note,
  };

  factory WeightModel.fromJson(Map<String, dynamic> json) => WeightModel(
    date: DateTime.parse(json['date']),
    weight: (json['weight'] ?? 0).toDouble(),
    note: json['note'],
  );
}
