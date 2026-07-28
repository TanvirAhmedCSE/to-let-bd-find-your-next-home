import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';

const String kAllAreasValue = 'All';

class AreaPickerField extends StatelessWidget {
  final String division;
  final String district;
  final String thana;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final ValueChanged<bool>? onAvailabilityChecked;
  final bool noAreasAvailable;

  const AreaPickerField({
    super.key,
    required this.division,
    required this.district,
    required this.thana,
    required this.selected,
    required this.onSelected,
    this.onAvailabilityChecked,
    this.noAreasAvailable = false,
  });

  bool get _enabled =>
      division.isNotEmpty &&
      district.isNotEmpty &&
      thana.isNotEmpty &&
      !noAreasAvailable;

  Future<void> _openPicker(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AreaPickerSheet(
        division: division,
        district: district,
        thana: thana,
        onAvailabilityChecked: onAvailabilityChecked,
      ),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _enabled ? () => _openPicker(context) : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Area',
              prefixIcon: const Icon(
                Icons.place_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              filled: true,
              fillColor: _enabled ? AppColors.surface : AppColors.divider,
              labelStyle: const TextStyle(color: AppColors.textSecondary),
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
              enabled: _enabled,
              helperText: !_enabled && noAreasAvailable
                  ? null
                  : _enabled
                  ? '(Optional)'
                  : 'Select Division, District and Thana first',
              helperStyle: const TextStyle(color: AppColors.textMuted),
            ),
            child: Text(
              selected ?? (noAreasAvailable ? 'No Area Found' : 'Select Area'),
              style: TextStyle(
                color: (selected == null)
                    ? AppColors.textMuted
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AreaPickerSheet extends StatefulWidget {
  final String division;
  final String district;
  final String thana;
  final ValueChanged<bool>? onAvailabilityChecked;

  const _AreaPickerSheet({
    required this.division,
    required this.district,
    required this.thana,
    this.onAvailabilityChecked,
  });

  @override
  State<_AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<_AreaPickerSheet> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _controller = TextEditingController();

  bool _loading = true;
  bool _hasAreas = true;
  List<String> _allAreas = []; // fetched once, excludes "All"
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    final prefix = LocationService.buildPrefix(
      division: widget.division,
      district: widget.district,
      thana: widget.thana,
    );
    final results = await _firestoreService.searchAreas(prefix);
    final names =
        results
            .map((e) => e['area'] as String? ?? '')
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (!mounted) return;
    final hasAreas = names.isNotEmpty;
    setState(() {
      _allAreas = names;
      _hasAreas = hasAreas;
      _filtered = hasAreas ? [kAllAreasValue, ...names] : [];
      _loading = false;
    });

    // Let the parent screen (Search screen) know right away, even if
    // the user hasn't picked anything or closes this sheet.
    widget.onAvailabilityChecked?.call(hasAreas);
  }

  void _onChanged(String query) {
    if (!_hasAreas) return; // field is disabled anyway when no areas
    setState(() {
      if (query.isEmpty) {
        _filtered = [kAllAreasValue, ..._allAreas];
      } else {
        final q = query.toLowerCase();
        final matches = [
          kAllAreasValue,
          ..._allAreas,
        ].where((name) => name.toLowerCase().contains(q)).toList();
        _filtered = matches;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('Select Area', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: _hasAreas,
                enabled: !_loading && _hasAreas,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: (!_loading && !_hasAreas)
                      ? 'No area available'
                      : 'Search available area name',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
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
                ),
                onChanged: _onChanged,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Not available',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final name = _filtered[index];
                          final isAll = name == kAllAreasValue;
                          return ListTile(
                            leading: Icon(
                              isAll ? Icons.apps_rounded : Icons.place_outlined,
                              color: isAll
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: isAll
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            onTap: () => Navigator.pop(context, name),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
