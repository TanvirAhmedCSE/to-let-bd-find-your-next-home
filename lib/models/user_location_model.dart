class UserLocationModel {
  final String division;
  final String district;
  final String thana;
  final String area;

  UserLocationModel({
    required this.division,
    required this.district,
    required this.thana,
    required this.area,
  });

  factory UserLocationModel.fromMap(Map<String, dynamic> map) {
    return UserLocationModel(
      division: map['division'] as String,
      district: map['district'] as String,
      thana: map['thana'] as String,
      area: map['area'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'division': division,
      'district': district,
      'thana': thana,
      'area': area,
    };
  }
}
