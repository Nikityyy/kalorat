/// Fitness goal for calorie target adjustment.
enum Goal {
  lose, // 0: Deficit (-500 kcal)
  maintain, // 1: Maintenance
  gain; // 2: Surplus (+500 kcal)

  static Goal fromIndex(int index) =>
      Goal.values[index.clamp(0, Goal.values.length - 1)];
}

/// Biological sex for BMR calculation.
enum Gender {
  male, // 0: +5 in Mifflin-St Jeor
  female; // 1: -161 in Mifflin-St Jeor

  static Gender fromIndex(int index) =>
      Gender.values[index.clamp(0, Gender.values.length - 1)];
}

/// Physical activity multiplier for TDEE.
enum ActivityLevel {
  sedentary, // 0: ×1.2
  light, // 1: ×1.375
  moderate, // 2: ×1.55
  active, // 3: ×1.725
  veryActive; // 4: ×1.9

  static const List<double> multipliers = [1.2, 1.375, 1.55, 1.725, 1.9];

  double get multiplier => multipliers[index];

  static ActivityLevel fromIndex(int index) =>
      ActivityLevel.values[index.clamp(0, ActivityLevel.values.length - 1)];
}
