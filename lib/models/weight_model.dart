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

  @HiveField(4)
  final DateTime updatedAt;

  WeightModel({
    required this.date,
    required this.weight,
    this.note,
    this.isPending = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  WeightModel copyWith({
    DateTime? date,
    double? weight,
    String? note,
    bool? isPending,
    DateTime? updatedAt,
  }) {
    return WeightModel(
      date: date ?? this.date,
      weight: weight ?? this.weight,
      note: note ?? this.note,
      isPending: isPending ?? this.isPending,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  void validate() {
    if (!weight.isFinite || weight < 20 || weight > 400) {
      throw const FormatException('Das Gewicht muss zwischen 20 und 400 kg liegen.');
    }
    if (date.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      throw const FormatException('Das Gewichtsdatum liegt in der Zukunft.');
    }
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'weight': weight,
    'note': note,
    'isPending': isPending,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WeightModel.fromJson(Map<String, dynamic> json) => WeightModel(
    date: DateTime.parse(json['date']),
    weight: (json['weight'] ?? 0).toDouble(),
    note: json['note'],
    isPending: json['isPending'] ?? false, // Default to synced if from cloud
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? ''),
  );
}
