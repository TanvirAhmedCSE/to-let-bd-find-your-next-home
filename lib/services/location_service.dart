import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class GeoItem {
  final String id;
  final String name;
  final String? parentId;
  GeoItem({required this.id, required this.name, this.parentId});
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  List<GeoItem> _divisions = [];
  List<GeoItem> _districts = [];
  List<GeoItem> _upazilas = [];
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    final divRaw = jsonDecode(
      await rootBundle.loadString('assets/data/divisions.json'),
    );
    final distRaw = jsonDecode(
      await rootBundle.loadString('assets/data/districts.json'),
    );
    final upzRaw = jsonDecode(
      await rootBundle.loadString('assets/data/upazilas.json'),
    );

    _divisions = (divRaw as List)
        .map((e) => GeoItem(id: e['id'].toString(), name: e['name']))
        .toList();
    _districts = (distRaw as List)
        .map(
          (e) => GeoItem(
            id: e['id'].toString(),
            name: e['name'],
            parentId: e['division_id'].toString(),
          ),
        )
        .toList();
    _upazilas = (upzRaw as List)
        .map(
          (e) => GeoItem(
            id: e['id'].toString(),
            name: e['name'],
            parentId: e['district_id'].toString(),
          ),
        )
        .toList();

    _divisions.sort((a, b) => a.name.compareTo(b.name));
    _districts.sort((a, b) => a.name.compareTo(b.name));
    _upazilas.sort((a, b) => a.name.compareTo(b.name));

    _loaded = true;
  }

  List<GeoItem> get allDivisions => _divisions;

  List<GeoItem> districtsOf(String divisionId) =>
      _districts.where((d) => d.parentId == divisionId).toList();

  List<GeoItem> upazilasOf(String districtId) =>
      _upazilas.where((u) => u.parentId == districtId).toList();

  List<GeoItem> filterDivisions(String query) {
    if (query.isEmpty) return _divisions;
    final q = query.toLowerCase();
    return _divisions.where((d) => d.name.toLowerCase().contains(q)).toList();
  }

  List<GeoItem> filterDistricts(String divisionId, String query) {
    final list = districtsOf(divisionId);
    if (query.isEmpty) return list;
    final q = query.toLowerCase();
    return list.where((d) => d.name.toLowerCase().contains(q)).toList();
  }

  List<GeoItem> filterUpazilas(String districtId, String query) {
    final list = upazilasOf(districtId);
    if (query.isEmpty) return list;
    final q = query.toLowerCase();
    return list.where((u) => u.name.toLowerCase().contains(q)).toList();
  }

  // Normalizes a name for use inside a search key:
  // lowercase, spaces removed, only letters/digits kept.
  static String normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  // Builds the "division_district_thana_" prefix used for area search.
  static String buildPrefix({
    required String division,
    required String district,
    required String thana,
  }) {
    return '${normalize(division)}_${normalize(district)}_${normalize(thana)}_';
  }

  // Builds the full area search key: "division_district_thana_area"
  static String buildAreaSearchKey({
    required String division,
    required String district,
    required String thana,
    required String area,
  }) {
    return '${buildPrefix(division: division, district: district, thana: thana)}${normalize(area)}';
  }
}
