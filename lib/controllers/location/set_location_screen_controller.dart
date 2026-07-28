import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';

class SetLocationScreenController extends ChangeNotifier {
  final LocationService locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  final bool isUpdateMode;

  final TextEditingController areaController = TextEditingController();

  GeoItem? division;
  GeoItem? district;
  GeoItem? thana;

  String? _initialDivision;
  String? _initialDistrict;
  String? _initialThana;
  String? _initialArea;

  bool locationLoaded = false;
  bool saving = false;
  String? errorMessage;

  SetLocationScreenController({this.isUpdateMode = false}) {
    // re-evaluate the button's enabled state on every keystroke
    areaController.addListener(notifyListeners);
    _init();
  }

  Future<void> _init() async {
    await locationService.load();

    if (isUpdateMode) {
      final existing = await _firestoreService.getUserLocation(
        _authService.currentUser!.uid,
      );
      if (existing != null) {
        division = locationService.allDivisions.firstWhere(
          (d) => d.name == existing.division,
          orElse: () => locationService.allDivisions.first,
        );
        district = locationService
            .districtsOf(division!.id)
            .firstWhere(
              (d) => d.name == existing.district,
              orElse: () => locationService.districtsOf(division!.id).first,
            );
        thana = locationService
            .upazilasOf(district!.id)
            .firstWhere(
              (u) => u.name == existing.thana,
              orElse: () => locationService.upazilasOf(district!.id).first,
            );
        areaController.text = existing.area;

        _initialDivision = division!.name;
        _initialDistrict = district!.name;
        _initialThana = thana!.name;
        _initialArea = existing.area;
      }
    }

    locationLoaded = true;
    notifyListeners();
  }

  bool get _allFilled =>
      division != null &&
      district != null &&
      thana != null &&
      areaController.text.trim().isNotEmpty;

  // Whether the Save/Update button should be enabled.
  bool get hasChanged {
    if (!_allFilled) return false;
    if (!isUpdateMode) return true; // fresh setup: just needs all 4 filled
    return division!.name != _initialDivision ||
        district!.name != _initialDistrict ||
        thana!.name != _initialThana ||
        areaController.text.trim() != _initialArea;
  }

  void setDivision(GeoItem item) {
    division = item;
    district = null;
    thana = null;
    areaController.clear();
    notifyListeners();
  }

  void setDistrict(GeoItem item) {
    district = item;
    thana = null;
    areaController.clear();
    notifyListeners();
  }

  void setThana(GeoItem item) {
    thana = item;
    areaController.clear();
    notifyListeners();
  }

  Future<bool> saveLocation() async {
    if (!_allFilled) {
      errorMessage = 'Select Division, District, Thana and Area';
      notifyListeners();
      return false;
    }

    saving = true;
    notifyListeners();
    try {
      final area = areaController.text.trim();
      final searchKey = LocationService.buildAreaSearchKey(
        division: division!.name,
        district: district!.name,
        thana: thana!.name,
        area: area,
      );

      await _firestoreService.ensureAreaExists(
        searchKey: searchKey,
        area: area,
        division: division!.name,
        district: district!.name,
        thana: thana!.name,
      );

      await _firestoreService.saveUserLocation(
        uid: _authService.currentUser!.uid,
        division: division!.name,
        district: district!.name,
        thana: thana!.name,
        area: area,
      );
      return true;
    } catch (e) {
      errorMessage = 'Failed to save location: $e';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    areaController.dispose();
    super.dispose();
  }
}
