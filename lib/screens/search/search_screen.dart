import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/search/search_screen_controller.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';
import '../../widgets/location_picker_field.dart';
import '../../widgets/post_card.dart';
import '../post/post_detail_screen.dart';
import '../../widgets/area_picker_field.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchScreenController(),
      child: const _SearchScreenView(),
    );
  }
}

class _SearchScreenView extends StatelessWidget {
  const _SearchScreenView();

  Future<void> _pickAvailableFromStart(
    BuildContext context,
    SearchScreenController controller,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.availableFromStart ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) controller.setAvailableFromStart(picked);
  }

  Future<void> _pickAvailableFromEnd(
    BuildContext context,
    SearchScreenController controller,
  ) async {
    final now = DateTime.now();
    final firstDate = controller.availableFromStart ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.availableFromEnd ?? firstDate,
      firstDate: firstDate,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) controller.setAvailableFromEnd(picked);
  }

  InputDecoration _fieldDecoration({
    required String label,
    IconData? icon,
    Widget? suffixIcon,
    bool enabled = true,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: AppColors.textSecondary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: enabled ? AppColors.surface : AppColors.divider,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: AppTextStyles.sectionTitle),
  );

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SearchScreenController>();

    if (!controller.locationLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset',
            onPressed: controller.resetSearch,
          ),
          const SizedBox(width: 13),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          TextField(
            controller: controller.keywordController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: _fieldDecoration(
              label: 'Search by title...',
              icon: Icons.search_rounded,
            ),
            onSubmitted: (_) => controller.search(),
          ),
          const SizedBox(height: 24),

          _sectionLabel('Filters'),
          DropdownButtonFormField<String>(
            value: controller.propertyType,
            style: const TextStyle(color: AppColors.textPrimary),
            dropdownColor: AppColors.surface,
            decoration: _fieldDecoration(
              label: 'Property Type (any)',
              icon: Icons.home_work_outlined,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Any')),
              ...kPropertyTypes.map(
                (t) => DropdownMenuItem(value: t, child: Text(t)),
              ),
            ],
            onChanged: controller.setPropertyType,
          ),
          const SizedBox(height: 16),

          _sectionLabel('Available From'),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _pickAvailableFromStart(context, controller),
                  child: InputDecorator(
                    decoration: _fieldDecoration(
                      label: 'Earliest',
                      icon: Icons.calendar_today_rounded,
                    ),
                    child: Text(
                      controller.availableFromStart == null
                          ? 'Any'
                          : DateFormat(
                              'd MMM, y',
                            ).format(controller.availableFromStart!),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: controller.availableFromStart == null
                      ? null
                      : () => _pickAvailableFromEnd(context, controller),
                  child: InputDecorator(
                    decoration: _fieldDecoration(
                      label: 'Latest',
                      icon: Icons.calendar_today_rounded,
                      enabled: controller.availableFromStart != null,
                    ),
                    child: Text(
                      controller.availableFromEnd == null
                          ? 'Any'
                          : DateFormat(
                              'd MMM, y',
                            ).format(controller.availableFromEnd!),
                      style: TextStyle(
                        color: controller.availableFromStart == null
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Pick "Earliest" only, or both to search within a date range',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 13),

          _sectionLabel('Location'),
          LocationPickerField(
            label: 'Division',
            selected: controller.division,
            items: controller.locationService.allDivisions,
            onSelected: controller.setDivision,
          ),
          const SizedBox(height: 16),
          LocationPickerField(
            label: 'District',
            selected: controller.district,
            enabled: controller.division != null,
            items: controller.division == null
                ? []
                : controller.locationService.districtsOf(
                    controller.division!.id,
                  ),
            onSelected: controller.setDistrict,
          ),
          const SizedBox(height: 16),
          LocationPickerField(
            label: 'Thana',
            selected: controller.thana,
            enabled: controller.district != null,
            items: controller.district == null
                ? []
                : controller.locationService.upazilasOf(
                    controller.district!.id,
                  ),
            onSelected: controller.setThana,
          ),
          const SizedBox(height: 16),
          AreaPickerField(
            division: controller.division?.name ?? '',
            district: controller.district?.name ?? '',
            thana: controller.thana?.name ?? '',
            selected: controller.selectedArea,
            onSelected: controller.setSelectedArea,
            onAvailabilityChecked: controller.setAreaAvailability,
            noAreasAvailable: controller.noAreasForThana,
          ),
          const SizedBox(height: 24),

          _sectionLabel('Budget'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.minRentController,
                  keyboardType: TextInputType.number,
                  enabled: !controller.noAreasForThana,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _fieldDecoration(
                    label: 'Min Rent',
                    icon: Icons.payments_outlined,
                    enabled: !controller.noAreasForThana,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller.maxRentController,
                  keyboardType: TextInputType.number,
                  enabled: !controller.noAreasForThana,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _fieldDecoration(
                    label: 'Max Rent',
                    icon: Icons.payments_outlined,
                    enabled: !controller.noAreasForThana,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (controller.searching || controller.noAreasForThana)
                  ? null
                  : controller.search,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textMuted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.searching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      controller.noAreasForThana
                          ? 'No Posts Available'
                          : 'Search',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          if (controller.results != null)
            controller.results!.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.search_off_rounded,
                            size: 36,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'No results found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.results!.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                    itemBuilder: (context, index) {
                      final PostModel post = controller.results![index];
                      return PostCard(
                        post: post,
                        showCategoryBadge: controller.propertyType == null,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(postId: post.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
        ],
      ),
    );
  }
}
