import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../models/calorie_info.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.onLogout,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  late ProfileViewModel _viewModel;
  final ImagePicker _imagePicker = ImagePicker();
  bool _waterRemindersEnabled = false;

  @override
  void initState() {
    super.initState();
    _viewModel = ProfileViewModel();
    _viewModel.loadUser();
    _loadWaterReminderState();
  }

  Future<void> _loadWaterReminderState() async {
    final enabled = await NotificationService().isEnabled();
    if (mounted) setState(() => _waterRemindersEnabled = enabled);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(viewModel),
                const SizedBox(height: 24),
                _buildHealthTargets(viewModel),
                const SizedBox(height: 24),
                _buildMealPreferences(viewModel),
                const SizedBox(height: 24),
                _buildWaterReminders(),
                const SizedBox(height: 24),
                _buildSignOutButton(),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(ProfileViewModel viewModel) {
    final user = viewModel.user;
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickProfileImage(viewModel),
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                backgroundImage: viewModel.profileImage != null
                    ? FileImage(viewModel.profileImage!)
                    : (user?.profileImagePath != null
                        ? FileImage(File(user!.profileImagePath!))
                        : null),
                child: (viewModel.profileImage == null && user?.profileImagePath == null)
                    ? Text(
                        user?.username[0].toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.username ?? 'User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.verified,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              user?.email ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickProfileImage(ProfileViewModel viewModel) async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );

    if (image != null) {
      viewModel.setProfileImage(File(image.path));
      await viewModel.updateProfileImagePath(image.path);
    }
  }

  Widget _buildHealthTargets(ProfileViewModel viewModel) {
    final user = viewModel.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Health Targets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Active Plan',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildGenderSelector(viewModel),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.height,
                label: 'HEIGHT',
                value: user?.height?.toStringAsFixed(0) ?? '--',
                unit: 'cm',
                onTap: () => _showEditNumberDialog(viewModel, 'height', 'Height', 'cm', user?.height),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.cake,
                label: 'AGE',
                value: user?.age?.toString() ?? '--',
                unit: 'yrs',
                onTap: () => _showEditNumberDialog(viewModel, 'age', 'Age', 'years', user?.age?.toDouble()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.monitor_weight_outlined,
                label: 'CURRENT',
                value: user?.currentWeight?.toStringAsFixed(1) ?? '--',
                unit: 'kg',
                onTap: () => _showEditWeightDialog(viewModel, 'current'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.flag,
                label: 'GOAL',
                value: user?.goalWeight?.toStringAsFixed(1) ?? '--',
                unit: 'kg',
                onTap: () => _showEditWeightDialog(viewModel, 'goal'),
                isHighlighted: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActivityLevelCard(viewModel),
        const SizedBox(height: 12),
        _buildGoalTypeCard(viewModel),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isHighlighted ? AppColors.primary : Colors.grey[500],
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? AppColors.primary : Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Icon(Icons.edit, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector(ProfileViewModel viewModel) {
    final selectedGender = viewModel.user?.gender;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                'GENDER',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildGenderOption(viewModel, 'male', 'Male', Icons.male, selectedGender == 'male'),
              const SizedBox(width: 12),
              _buildGenderOption(viewModel, 'female', 'Female', Icons.female, selectedGender == 'female'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(ProfileViewModel viewModel, String value, String label, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => viewModel.updateGender(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityLevelCard(ProfileViewModel viewModel) {
    final currentLevel = ActivityLevel.fromString(viewModel.user?.activityLevel);

    return GestureDetector(
      onTap: () => _showActivityLevelDialog(viewModel),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_run, size: 18, color: Colors.orange[600]),
                const SizedBox(width: 8),
                Text(
                  'ACTIVITY LEVEL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Icon(Icons.edit, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currentLevel.label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentLevel.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTypeCard(ProfileViewModel viewModel) {
    final currentGoal = GoalType.fromString(viewModel.user?.goalType);

    return GestureDetector(
      onTap: () => _showGoalTypeDialog(viewModel),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes, size: 18, color: Colors.purple[600]),
                const SizedBox(width: 8),
                Text(
                  'NUTRITION GOAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Icon(Icons.edit, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              currentGoal.label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              currentGoal.description,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealPreferences(ProfileViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Meal Preferences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMealsPerDayCard(viewModel),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMaxCookTimeCard(viewModel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMealsPerDayCard(ProfileViewModel viewModel) {
    final mealsPerDay = viewModel.user?.preferredMealsPerDay ?? 3;

    return GestureDetector(
      onTap: () => _showMealsPerDayDialog(viewModel),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant_menu, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'MEALS/DAY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Icon(Icons.edit, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  mealsPerDay.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 4),
                  child: Text(
                    'meals',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxCookTimeCard(ProfileViewModel viewModel) {
    final maxCookTime = viewModel.user?.maxCookTime;
    final hasLimit = maxCookTime != null;

    return GestureDetector(
      onTap: () => _showMaxCookTimeDialog(viewModel),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'COOK TIME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Icon(Icons.edit, size: 14, color: Colors.grey[400]),
              ],
            ),
            const SizedBox(height: 8),
            hasLimit
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        maxCookTime.toString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Text(
                          'min',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    'No limit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showMealsPerDayDialog(ProfileViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meals Per Day',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSelectionOption(
              label: '3 Meals',
              description: 'Breakfast, Lunch, Dinner',
              isSelected: (viewModel.user?.preferredMealsPerDay ?? 3) == 3,
              onTap: () {
                Navigator.pop(context);
                viewModel.updatePreferredMealsPerDay(3);
              },
            ),
            _buildSelectionOption(
              label: '4 Meals',
              description: 'Breakfast, Lunch, Snack, Dinner',
              isSelected: viewModel.user?.preferredMealsPerDay == 4,
              onTap: () {
                Navigator.pop(context);
                viewModel.updatePreferredMealsPerDay(4);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showMaxCookTimeDialog(ProfileViewModel viewModel) {
    final controller = TextEditingController(
      text: viewModel.user?.maxCookTime?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Max Cook Time'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set the maximum cooking time for recipes in your meal plans.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Minutes',
                hintText: 'e.g. 30',
                suffixText: 'min',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.updateMaxCookTime(null, clear: true);
            },
            child: Text(
              'No Limit',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context);
                viewModel.updateMaxCookTime(value);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showActivityLevelDialog(ProfileViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Activity Level',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...ActivityLevel.values.map((level) => _buildSelectionOption(
              label: level.label,
              description: level.description,
              isSelected: viewModel.user?.activityLevel == level.value,
              onTap: () {
                Navigator.pop(context);
                viewModel.updateActivityLevel(level.value);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showGoalTypeDialog(ProfileViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Nutrition Goal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...GoalType.values.map((goal) => _buildSelectionOption(
              label: goal.label,
              description: goal.description,
              isSelected: viewModel.user?.goalType == goal.value,
              onTap: () {
                Navigator.pop(context);
                viewModel.updateGoalType(goal.value);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionOption({
    required String label,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryWithOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  void _showEditNumberDialog(ProfileViewModel viewModel, String type, String title, String unit, double? currentValue) {
    final controller = TextEditingController(
      text: currentValue?.toStringAsFixed(0) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: TextField(
          controller: controller,
          keyboardType: type == 'age'
              ? TextInputType.number
              : const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: '$title ($unit)',
            hintText: type == 'height' ? 'e.g. 175' : 'e.g. 25',
            suffixText: unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context);
                if (type == 'height') {
                  viewModel.updateHeight(value);
                } else if (type == 'age') {
                  viewModel.updateAge(value.toInt());
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditWeightDialog(ProfileViewModel viewModel, String type) {
    final isCurrentWeight = type == 'current';
    final currentValue = isCurrentWeight ? viewModel.user?.currentWeight : viewModel.user?.goalWeight;
    final controller = TextEditingController(
      text: currentValue?.toStringAsFixed(1) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isCurrentWeight ? 'Current Weight' : 'Goal Weight'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Weight (kg)',
            hintText: 'e.g. 68.5',
            suffixText: 'kg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context);
                if (isCurrentWeight) {
                  viewModel.updateCurrentWeight(value);
                } else {
                  viewModel.updateGoalWeight(value);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterReminders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.water_drop, color: Colors.blue[400], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Water Reminders',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Every 2 hours from 8 AM to 8 PM',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _waterRemindersEnabled,
                onChanged: (value) async {
                  final service = NotificationService();
                  if (value) {
                    final granted = await service.requestPermission();
                    if (!granted && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification permission denied. Please enable it in Settings.'),
                        ),
                      );
                      return;
                    }
                    await service.enableWaterReminders();
                  } else {
                    await service.disableWaterReminders();
                  }
                  if (mounted) setState(() => _waterRemindersEnabled = value);
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton() {
    return TextButton.icon(
      onPressed: widget.onLogout,
      icon: Icon(Icons.logout, color: Colors.red[400], size: 18),
      label: Text(
        'Sign Out',
        style: TextStyle(
          color: Colors.red[400],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
