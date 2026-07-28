import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/post_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';

class EditPostScreenController extends ChangeNotifier {
  final PostModel post;

  final LocationService locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  late final TextEditingController titleController;
  late final TextEditingController descController;
  late final TextEditingController rentController;
  late final TextEditingController bedroomsController;
  late final TextEditingController bathroomsController;
  late final TextEditingController areaController;

  late String propertyType;
  GeoItem? division;
  GeoItem? district;
  GeoItem? thana;
  late Set<String> selectedFacilities;
  DateTime? availableFrom;

  // existing images kept + newly picked local files
  late List<PostImage> existingImages;
  final List<String> removedPublicIds = [];
  final List<File> newImages = [];

  bool locationLoaded = false;
  bool saving = false;
  String? errorMessage;

  EditPostScreenController(this.post) {
    titleController = TextEditingController(text: post.title);
    descController = TextEditingController(text: post.description);
    rentController = TextEditingController(text: post.rent.toStringAsFixed(0));
    bedroomsController = TextEditingController(text: post.bedrooms.toString());
    bathroomsController = TextEditingController(
      text: post.bathrooms.toString(),
    );
    areaController = TextEditingController(text: post.area);
    propertyType = post.propertyType;
    selectedFacilities = post.facilities.toSet();
    existingImages = List.of(post.images);
    availableFrom = post.availableFrom?.toDate();

    _loadLocations();
  }

  Future<void> _loadLocations() async {
    await locationService.load();
    division = locationService.allDivisions.firstWhere(
      (d) => d.name == post.division,
      orElse: () => locationService.allDivisions.first,
    );
    district = locationService
        .districtsOf(division!.id)
        .firstWhere(
          (d) => d.name == post.district,
          orElse: () => locationService.districtsOf(division!.id).first,
        );
    thana = locationService
        .upazilasOf(district!.id)
        .firstWhere(
          (u) => u.name == post.thana,
          orElse: () => locationService.upazilasOf(district!.id).first,
        );
    locationLoaded = true;
    notifyListeners();
  }

  void setPropertyType(String value) {
    propertyType = value;
    notifyListeners();
  }

  void setDivision(GeoItem item) {
    division = item;
    district = locationService.districtsOf(item.id).first;
    thana = locationService.upazilasOf(district!.id).first;
    notifyListeners();
  }

  void setDistrict(GeoItem item) {
    district = item;
    thana = locationService.upazilasOf(item.id).first;
    notifyListeners();
  }

  void setThana(GeoItem item) {
    thana = item;
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
      newImages.addAll(picked.map((x) => File(x.path)));
      notifyListeners();
    }
  }

  void removeNewImage(File file) {
    newImages.remove(file);
    notifyListeners();
  }

  void removeExistingImage(PostImage image) {
    existingImages.remove(image);
    removedPublicIds.add(image.publicId);
    notifyListeners();
  }

  Future<bool> save() async {
    errorMessage = null;
    if (division == null || district == null || thana == null) return false;
    if (availableFrom == null) {
      errorMessage = 'Select available-from date';
      notifyListeners();
      return false;
    }

    saving = true;
    notifyListeners();
    try {
      // Upload any newly added images
      final uploadedNew = <PostImage>[];
      for (final file in newImages) {
        final result = await _cloudinaryService.uploadImage(file);
        uploadedNew.add(PostImage(url: result.url, publicId: result.publicId));
      }

      // Delete images the uploader removed
      if (removedPublicIds.isNotEmpty) {
        await _cloudinaryService.deleteImages(removedPublicIds);
      }

      final finalImages = [...existingImages, ...uploadedNew];

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

      await _firestoreService.updatePost(post.id, {
        'propertyType': propertyType,
        'title': titleController.text.trim(),
        'description': descController.text.trim(),
        'rent': double.tryParse(rentController.text.trim()) ?? 0,
        'division': division!.name,
        'district': district!.name,
        'thana': thana!.name,
        'area': areaController.text.trim(),
        'areaSearchKey': searchKey,
        'bedrooms': int.tryParse(bedroomsController.text.trim()) ?? 0,
        'bathrooms': int.tryParse(bathroomsController.text.trim()) ?? 0,
        'facilities': selectedFacilities.toList(),
        'availableFrom': Timestamp.fromDate(availableFrom!),
        'images': finalImages.map((e) => e.toMap()).toList(),
      });
      return true;
    } catch (e) {
      errorMessage = 'Failed to update: $e';
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
