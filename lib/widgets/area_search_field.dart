import 'dart:async';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

class AreaSearchField extends StatefulWidget {
  final String division;
  final String district;
  final String thana;
  final TextEditingController controller;
  final String label;

  const AreaSearchField({
    super.key,
    required this.division,
    required this.district,
    required this.thana,
    required this.controller,
    this.label = 'Area (e.g. Mirpur 11)',
  });

  @override
  State<AreaSearchField> createState() => _AreaSearchFieldState();
}

class _AreaSearchFieldState extends State<AreaSearchField> {
  final FirestoreService _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;

  bool get _locationReady =>
      widget.division.isNotEmpty &&
      widget.district.isNotEmpty &&
      widget.thana.isNotEmpty;

  void _onChanged(String value) {
    _debounce?.cancel();
    if (!_locationReady || value.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final prefix =
          LocationService.buildPrefix(
            division: widget.division,
            district: widget.district,
            thana: widget.thana,
          ) +
          LocationService.normalize(value);
      setState(() => _loading = true);
      final results = await _firestoreService.searchAreas(prefix);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: _locationReady,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: const Icon(
              Icons.place_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            filled: true,
            fillColor: _locationReady ? AppColors.surface : AppColors.divider,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.6,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.6),
            ),
            helperText: _locationReady
                ? null
                : 'Select Division, District and Thana first',
            helperStyle: const TextStyle(color: AppColors.textMuted),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          onChanged: _onChanged,
          validator: (value) =>
              (value == null || value.trim().isEmpty) ? 'Enter area' : null,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, index) {
                  final area = _suggestions[index]['area'] as String;
                  return ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.place_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    title: Text(
                      area,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      widget.controller.text = area;
                      setState(() => _suggestions = []);
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
