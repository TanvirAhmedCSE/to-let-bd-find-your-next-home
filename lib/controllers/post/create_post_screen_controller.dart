import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/post_model.dart';
import '../../services/auth_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../utils/constants.dart';

class CreatePostScreenController extends ChangeNotifier {
  final LocationService locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final AuthService _authService = AuthService();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController bedroomsController = TextEditingController(
    text: '0',
  );
  final TextEditingController bathroomsController = TextEditingController(
    text: '0',
  );
  final TextEditingController areaController = TextEditingController();

  String propertyType = kPropertyTypes.first;
  GeoItem? division;
  GeoItem? district;
  GeoItem? thana;
  DateTime? availableFrom;
  final Set<String> selectedFacilities = {};
  final List<File> images = [];

  bool locationLoaded = false;
  bool saving = false;
  String? errorMessage;

  CreatePostScreenController() {
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    await locationService.load();
    locationLoaded = true;
    notifyListeners();
  }

  void setPropertyType(String value) {
    propertyType = value;
    notifyListeners();
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

  void setAvailableFrom(DateTime picked) {
    availableFrom = picked;
    notifyListeners();
  }

  void toggleFacility(String facility, bool selected) {
    if (selected) {
      selectedFacilities.add(facility);
    } else {
      selectedFacilities.remove(facility);
    }
    notifyListeners();
  }

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      images.addAll(picked.map((x) => File(x.path)));
      notifyListeners();
    }
  }

  void removeImage(File file) {
    images.remove(file);
    notifyListeners();
  }

  Future<bool> publish() async {
    errorMessage = null;

    if (division == null || district == null || thana == null) {
      errorMessage = 'Select Division, District and Thana';
      notifyListeners();
      return false;
    }
    if (images.isEmpty) {
      errorMessage = 'Add at least one image';
      notifyListeners();
      return false;
    }
    if (availableFrom == null) {
      errorMessage = 'Select available-from date';
      notifyListeners();
      return false;
    }

    saving = true;
    notifyListeners();
    try {
      // 1. Upload images to Cloudinary
      final uploaded = <PostImage>[];
      for (final file in images) {
        final result = await _cloudinaryService.uploadImage(file);
        uploaded.add(PostImage(url: result.url, publicId: result.publicId));
      }

      // 2. Build area search key + ensure area doc exists
      final searchKey = LocationService.buildAreaSearchKey(
        division: division!.name,
        district: district!.name,
        thana: thana!.name,
        area: areaController.text.trim(),
      );
      await _firestoreService.ensureAreaExists(
        searchKey: searchKey,
        area: areaController.text.trim(),
        division: division!.name,
        district: district!.name,
        thana: thana!.name,
      );

      // 3. Get uploader profile info
      final user = _authService.currentUser!;

      final post = PostModel(
        id: '',
        uploaderUid: user.uid,
        uploaderName: user.displayName ?? user.email ?? 'User',
        uploaderPhone: '', // filled in from users/{uid} doc in real usage
        propertyType: propertyType,
        title: titleController.text.trim(),
        description: descController.text.trim(),
        rent: double.tryParse(rentController.text.trim()) ?? 0,
        division: division!.name,
        district: district!.name,
        thana: thana!.name,
        area: areaController.text.trim(),
        areaSearchKey: searchKey,
        bedrooms: int.tryParse(bedroomsController.text.trim()) ?? 0,
        bathrooms: int.tryParse(bathroomsController.text.trim()) ?? 0,
        facilities: selectedFacilities.toList(),
        availableFrom: Timestamp.fromDate(availableFrom!),
        images: uploaded,
        status: kStatusActive,
      );

      await _firestoreService.createPost(post);
      return true;
    } catch (e) {
      errorMessage = 'Failed to publish: $e';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    rentController.dispose();
    bedroomsController.dispose();
    bathroomsController.dispose();
    areaController.dispose();
    super.dispose();
  }
}
