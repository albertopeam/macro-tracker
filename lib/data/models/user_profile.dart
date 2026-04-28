enum Sex { male, female }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  extremelyActive,
}

extension ActivityLevelX on ActivityLevel {
  double get multiplier => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.lightlyActive => 1.375,
        ActivityLevel.moderatelyActive => 1.55,
        ActivityLevel.veryActive => 1.725,
        ActivityLevel.extremelyActive => 1.9,
      };

  String get label => switch (this) {
        ActivityLevel.sedentary => 'Sedentary',
        ActivityLevel.lightlyActive => 'Lightly active',
        ActivityLevel.moderatelyActive => 'Moderately active',
        ActivityLevel.veryActive => 'Very active',
        ActivityLevel.extremelyActive => 'Extremely active',
      };
}

class UserProfile {
  final Sex sex;
  final int age;
  final double weightKg;
  final double heightCm;
  final ActivityLevel activityLevel;

  const UserProfile({
    required this.sex,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.activityLevel,
  });

  Map<String, dynamic> toJson() => {
        'sex': sex.name,
        'age': age,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'activityLevel': activityLevel.name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        sex: Sex.values.byName(j['sex'] as String),
        age: (j['age'] as num).toInt(),
        weightKg: (j['weightKg'] as num).toDouble(),
        heightCm: (j['heightCm'] as num).toDouble(),
        activityLevel: ActivityLevel.values.byName(j['activityLevel'] as String),
      );
}
