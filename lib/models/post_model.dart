import 'package:cloud_firestore/cloud_firestore.dart';

class PostImage {
  final String url;
  final String publicId;

  PostImage({required this.url, required this.publicId});

  factory PostImage.fromMap(Map<String, dynamic> map) {
    return PostImage(url: map['url'] ?? '', publicId: map['publicId'] ?? '');
  }

  Map<String, dynamic> toMap() => {'url': url, 'publicId': publicId};
}

class PostModel {
  final String id;
  final String uploaderUid;
  final String uploaderName;
  final String uploaderPhone;
  final String propertyType;
  final String title;
  final String description;
  final double rent;
  final String division;
  final String district;
  final String thana;
  final String area;
  final String areaSearchKey;
  final int bedrooms;
  final int bathrooms;
  final List<String> facilities;
  final Timestamp? availableFrom;
  final List<PostImage> images;
  final String status;
  final int interestedCount;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  PostModel({
    required this.id,
    required this.uploaderUid,
    required this.uploaderName,
    required this.uploaderPhone,
    required this.propertyType,
    required this.title,
    required this.description,
    required this.rent,
    required this.division,
    required this.district,
    required this.thana,
    required this.area,
    required this.areaSearchKey,
    required this.bedrooms,
    required this.bathrooms,
    required this.facilities,
    this.availableFrom,
    required this.images,
    this.status = kActive,
    this.interestedCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  static const kActive = 'active';

  factory PostModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      uploaderUid: map['uploaderUid'] ?? '',
      uploaderName: map['uploaderName'] ?? '',
      uploaderPhone: map['uploaderPhone'] ?? '',
      propertyType: map['propertyType'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rent: (map['rent'] ?? 0).toDouble(),
      division: map['division'] ?? '',
      district: map['district'] ?? '',
      thana: map['thana'] ?? '',
      area: map['area'] ?? '',
      areaSearchKey: map['areaSearchKey'] ?? '',
      bedrooms: map['bedrooms'] ?? 0,
      bathrooms: map['bathrooms'] ?? 0,
      facilities: List<String>.from(map['facilities'] ?? []),
      availableFrom: map['availableFrom'],
      images: (map['images'] as List<dynamic>? ?? [])
          .map((e) => PostImage.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      status: map['status'] ?? 'active',
      interestedCount: map['interestedCount'] ?? 0,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uploaderUid': uploaderUid,
      'uploaderName': uploaderName,
      'uploaderPhone': uploaderPhone,
      'propertyType': propertyType,
      'title': title,
      'description': description,
      'rent': rent,
      'division': division,
      'district': district,
      'thana': thana,
      'area': area,
      'areaSearchKey': areaSearchKey,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'facilities': facilities,
      'availableFrom': availableFrom,
      'images': images.map((e) => e.toMap()).toList(),
      'status': status,
      'interestedCount': interestedCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
