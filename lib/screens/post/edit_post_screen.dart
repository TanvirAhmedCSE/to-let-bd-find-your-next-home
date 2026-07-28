import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../controllers/post/edit_post_screen_controller.dart';
import '../../models/post_model.dart';
import '../../utils/constants.dart';
import '../../widgets/area_search_field.dart';
import '../../widgets/location_picker_field.dart';

class EditPostScreen extends StatelessWidget {
  final PostModel post;
  const EditPostScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditPostScreenController(post),
      child: const _EditPostScreenView(),
    );
  }
}

class _EditPostScreenView extends StatefulWidget {
  const _EditPostScreenView();

  @override
  State<_EditPostScreenView> createState() => _EditPostScreenViewState();
}

class _EditPostScreenViewState extends State<_EditPostScreenView> {
  final _formKey = GlobalKey<FormState>();

  Future<void> _pickAvailableFrom(EditPostScreenController controller) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.availableFrom ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) controller.setAvailableFrom(picked);
  }

  Future<void> _save(EditPostScreenController controller) async {
    if (!_formKey.currentState!.validate()) return;
    if (controller.division == null ||
        controller.district == null ||
        controller.thana == null) {
      return;
    }

    final success = await controller.save();
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage ?? 'Failed to update')),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Post updated')));
    Navigator.of(context).pop();
  }

  InputDecoration _fieldDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: AppColors.surface,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: AppTextStyles.sectionTitle),
  );

  Widget _facilityChip(EditPostScreenController controller, String f) {
    final selected = controller.selectedFacilities.contains(f);
    return FilterChip(
      label: Text(f),
      selected: selected,
      showCheckmark: false,
      onSelected: (v) => controller.toggleFacility(f, v),
      backgroundColor: AppColors.primaryLight,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditPostScreenController>();

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
        title: const Text('Edit Post'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionLabel('Basic Info'),
            DropdownButtonFormField<String>(
              value: controller.propertyType,
              style: const TextStyle(color: AppColors.textPrimary),
              dropdownColor: AppColors.surface,
              decoration: _fieldDecoration(
                label: 'Property Type',
                icon: Icons.home_work_outlined,
              ),
              items: kPropertyTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => controller.setPropertyType(v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration(
                label: 'Title',
                icon: Icons.title_rounded,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter title' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.descController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration(
                label: 'Description (Road no., House no., Phone etc.)',
                icon: Icons.notes_rounded,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller.rentController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: _fieldDecoration(
                label: 'Rent (BDT)',
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(height: 24),

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
              items: controller.locationService.districtsOf(
                controller.division!.id,
              ),
              onSelected: controller.setDistrict,
            ),
            const SizedBox(height: 16),
            LocationPickerField(
              label: 'Thana',
              selected: controller.thana,
              items: controller.locationService.upazilasOf(
                controller.district!.id,
              ),
              onSelected: controller.setThana,
            ),
            const SizedBox(height: 16),
            AreaSearchField(
              division: controller.division?.name ?? '',
              district: controller.district?.name ?? '',
              thana: controller.thana?.name ?? '',
              controller: controller.areaController,
            ),
            const SizedBox(height: 24),

            _sectionLabel('Details'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller.bedroomsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _fieldDecoration(
                      label: 'Bedrooms',
                      icon: Icons.bed_outlined,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller.bathroomsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: _fieldDecoration(
                      label: 'Bathrooms',
                      icon: Icons.bathtub_outlined,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionLabel('Facilities'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kFacilities
                  .map((f) => _facilityChip(controller, f))
                  .toList(),
            ),
            const SizedBox(height: 24),

            _sectionLabel('Availability'),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickAvailableFrom(controller),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      controller.availableFrom == null
                          ? 'Available From'
                          : DateFormat(
                              'd MMMM, y',
                            ).format(controller.availableFrom!),
                      style: TextStyle(
                        color: controller.availableFrom == null
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel('Images'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ...controller.existingImages.map(
                  (img) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          img.url,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => controller.removeExistingImage(img),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...controller.newImages.map(
                  (file) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          file,
                          width: 92,
                          height: 92,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: GestureDetector(
                          onTap: () => controller.removeNewImage(file),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: controller.pickImages,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: controller.saving
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => _save(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 29),
          ],
        ),
      ),
    );
  }
}
