import 'package:hive/hive.dart';

part 'weight_model.g.dart';

@HiveType(typeId: 2)
class WeightModel extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final double weight; // in kg

  @HiveField(2)
  final String? note;

  @HiveField(3)
  final bool isPending;

  WeightModel({
    required this.date,
    required this.weight,
    this.note,
    this.isPending = true,
  });

  WeightModel copyWith({
    DateTime? date,
    double? weight,
    String? note,
    bool? isPending,
  }) {
    return WeightModel(
      date: date ?? this.date,
      weight: weight ?? this.weight,
      note: note ?? this.note,
      isPending: isPending ?? this.isPending,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
    'note': note,
    'isPending': isPending,
  };

  factory WeightModel.fromJson(Map<String, dynamic> json) => WeightModel(
    date: DateTime.parse(json['date']),
    weight: (json['weight'] ?? 0).toDouble(),
    note: json['note'],
    isPending: json['isPending'] ?? false, // Default to synced if from cloud
  );
}
