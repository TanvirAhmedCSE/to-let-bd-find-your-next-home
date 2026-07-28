import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';

class SearchScreenController extends ChangeNotifier {
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();

  LocationService get locationService => _locationService;

  final TextEditingController keywordController = TextEditingController();
  final TextEditingController minRentController = TextEditingController();
  final TextEditingController maxRentController = TextEditingController();

  String? propertyType;
  GeoItem? division;
  GeoItem? district;
  GeoItem? thana;
  String? selectedArea;

  bool locationLoaded = false;
  bool searching = false;
  List<PostModel>? results;
  bool noAreasForThana = false;

  DateTime? availableFromStart;
  DateTime? availableFromEnd;

  SearchScreenController() {
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    await _locationService.load();
    locationLoaded = true;
    notifyListeners();
  }

  void setPropertyType(String? value) {
    propertyType = value;
    notifyListeners();
  }

  void setDivision(GeoItem item) {
    division = item;
    district = null;
    thana = null;
    notifyListeners();
  }

  void setDistrict(GeoItem item) {
    district = item;
    thana = null;
    notifyListeners();
  }

  void setThana(GeoItem item) {
    thana = item;
    selectedArea = null;
    noAreasForThana = false; // reset until AreaPickerField checks again
    notifyListeners();
  }

  void setSelectedArea(String? value) {
    selectedArea = value;
    notifyListeners();
  }

  void setAreaAvailability(bool hasAreas) {
    noAreasForThana = !hasAreas;
    notifyListeners();
  }

  void setAvailableFromStart(DateTime picked) {
    availableFromStart = picked;
    // if end date is now before start, clear it so range stays valid
    if (availableFromEnd != null && availableFromEnd!.isBefore(picked)) {
      availableFromEnd = null;
    }
    notifyListeners();
  }

  void setAvailableFromEnd(DateTime picked) {
    availableFromEnd = picked;
    notifyListeners();
  }

  void resetSearch() {
    keywordController.clear();
    minRentController.clear();
    maxRentController.clear();

    propertyType = null;
    division = null;
    district = null;
    thana = null;
    selectedArea = null;

    noAreasForThana = false;
    availableFromStart = null;
    availableFromEnd = null;

    results = null;
    searching = false;
    notifyListeners();
  }

  Future<void> search() async {
    searching = true;
    notifyListeners();
    try {
      var searchResults = await _firestoreService.searchPosts(
        propertyType: propertyType,
        division: division?.name,
        district: district?.name,
        thana: thana?.name,
        area: selectedArea,
        minRent: double.tryParse(minRentController.text.trim()),
        maxRent: double.tryParse(maxRentController.text.trim()),
      );

      // search by title
      final keyword = keywordController.text.trim().toLowerCase();
      if (keyword.isNotEmpty) {
        searchResults = searchResults
            .where((p) => p.title.toLowerCase().contains(keyword))
            .toList();
      }
      results = searchResults;
    } finally {
      searching = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    keywordController.dispose();
    minRentController.dispose();
    maxRentController.dispose();
    super.dispose();
  }
}
