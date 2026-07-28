import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary = Color(0xFF1B4B43);
  static const Color primaryDark = Color(0xFF11322D);
  static const Color primaryLight = Color(0xFFE3ECE9);

  // Accent (CTAs, highlights, links)
  static const Color accent = Color(0xFFC1502E);
  static const Color accentDark = Color(0xFF9B3F23);
  static const Color accentLight = Color(0xFFF3E1D8);

  // Status
  static const Color success = Color(0xFF3F7D58);
  static const Color error = Color(0xFFB3261E);
  static const Color warning = Color(0xFFC17A17);

  // Neutrals
  static const Color background = Color(0xFFF5F6F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDCE0DA);
  static const Color divider = Color(0xFFE7E9E3);

  // Text
  static const Color textPrimary = Color(0xFF1E2A28);
  static const Color textSecondary = Color(0xFF6E7A76);
  static const Color textMuted = Color(0xFF9AA39F);
}

class AppTextStyles {
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}

// Property types shown as chips on Home / Create Post / Search
const List<String> kPropertyTypes = [
  'Family Flat',
  'Bachelor Flat',
  'Bachelor Room',
  'Bachelor Seat',
  'Shop',
  'Studio',
  'Office',
];

// Facilities checklist used in Create/Edit Post
const List<String> kFacilities = [
  'Lift',
  'Generator',
  'Gas',
  'Parking',
  'CCTV',
  'Security Guard',
  'Water Reserve Tank',
  'Balcony',
  'Furnished',
];

// Post status
const String kStatusActive = 'active';
const String kStatusRented = 'rented';

// Notification types
const String kNotifInterested = 'interested';
const String kNotifPostRented = 'post_rented';
const String kNotifRentAvailable = 'rent_available';

class CloudinaryConfig {
  static const String cloudName = 'REPLACE_IT';
  static const String uploadPreset = 'to-let-bd-app'; // you can rename it
  static const String apiKey = 'REPLACE_IT';
  static const String apiSecret = 'REPLACE_IT';
}
