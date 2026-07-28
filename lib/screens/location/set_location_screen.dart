import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/location/set_location_screen_controller.dart';
import '../../utils/constants.dart';
import '../../widgets/area_search_field.dart';
import '../../widgets/location_picker_field.dart';
import '../home/main_screen.dart';

class SetLocationScreen extends StatelessWidget {
  final bool isUpdateMode;
  const SetLocationScreen({super.key, this.isUpdateMode = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SetLocationScreenController(isUpdateMode: isUpdateMode),
      child: _SetLocationScreenView(isUpdateMode: isUpdateMode),
    );
  }
}

class _SetLocationScreenView extends StatelessWidget {
  final bool isUpdateMode;
  const _SetLocationScreenView({required this.isUpdateMode});

  Future<void> _save(
    BuildContext context,
    SetLocationScreenController controller,
  ) async {
    final success = await controller.saveLocation();
    if (!context.mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Failed to save location'),
        ),
      );
      return;
    }

    if (isUpdateMode) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
  }

  void _skip(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SetLocationScreenController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isUpdateMode ? 'Update Location' : 'Set Location'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: isUpdateMode,
        actions: [
          if (!isUpdateMode)
            TextButton(
              onPressed: () => _skip(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text(
                'Skip',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: !controller.locationLoaded
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  isUpdateMode ? 'Update Your Location' : 'Set Your Location',
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: 4),
                const Text(
                  "Tell us where you're looking for a place, so we can "
                  "show you posts nearby.",
                  style: AppTextStyles.subheading,
                ),
                const SizedBox(height: 24),

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
                AreaSearchField(
                  division: controller.division?.name ?? '',
                  district: controller.district?.name ?? '',
                  thana: controller.thana?.name ?? '',
                  controller: controller.areaController,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (controller.hasChanged && !controller.saving)
                        ? () => _save(context, controller)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.textMuted,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isUpdateMode ? 'Update Location' : 'Set Location',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}
