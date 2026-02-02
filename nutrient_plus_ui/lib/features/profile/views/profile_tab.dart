import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/api_service.dart';
import '../../auth/models/user.dart';
import '../models/calorie_info.dart';
import '../../../core/constants/app_colors.dart';

class ProfileTab extends StatefulWidget {
  final User? user;
  final Function(User?) onUserUpdated;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.user,
    required this.onUserUpdated,
    required this.onLogout,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  File? _profileImage;
  final ImagePicker _imagePicker = ImagePicker();

  User? get _user => widget.user;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildHealthTargets(),
          const SizedBox(height: 24),
          _buildSyncSettings(),
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
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickProfileImage,
          child: Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : (_user?.profileImagePath != null
                        ? FileImage(File(_user!.profileImagePath!))
                        : null),
                child: (_profileImage == null && _user?.profileImagePath == null)
                    ? Text(
                        _user?.username[0].toUpperCase() ?? 'U',
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
          _user?.username ?? 'User',
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
              _user?.email ?? '',
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

  Future<void> _pickProfileImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
      await ApiService.updateProfile(profileImagePath: image.path);
    }
  }

  Widget _buildHealthTargets() {
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
        _buildGenderSelector(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.height,
                label: 'HEIGHT',
                value: _user?.height?.toStringAsFixed(0) ?? '--',
                unit: 'cm',
                onTap: () => _showEditNumberDialog('height', 'Height', 'cm', _user?.height),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.cake,
                label: 'AGE',
                value: _user?.age?.toString() ?? '--',
                unit: 'yrs',
                onTap: () => _showEditNumberDialog('age', 'Age', 'years', _user?.age?.toDouble()),
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
                value: _user?.currentWeight?.toStringAsFixed(1) ?? '--',
                unit: 'kg',
                onTap: () => _showEditWeightDialog('current'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.flag,
                label: 'GOAL',
                value: _user?.goalWeight?.toStringAsFixed(1) ?? '--',
                unit: 'kg',
                onTap: () => _showEditWeightDialog('goal'),
                isHighlighted: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildActivityLevelCard(),
        const SizedBox(height: 12),
        _buildGoalTypeCard(),
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

  Widget _buildGenderSelector() {
    final selectedGender = _user?.gender;

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
              _buildGenderOption('male', 'Male', Icons.male, selectedGender == 'male'),
              const SizedBox(width: 12),
              _buildGenderOption('female', 'Female', Icons.female, selectedGender == 'female'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _updateGender(value),
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

  Future<void> _updateGender(String gender) async {
    final updatedUser = _user?.copyWith(gender: gender);
    widget.onUserUpdated(updatedUser);
    await ApiService.updateProfile(gender: gender);
  }

  Widget _buildActivityLevelCard() {
    final currentLevel = ActivityLevel.fromString(_user?.activityLevel);

    return GestureDetector(
      onTap: () => _showActivityLevelDialog(),
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

  Widget _buildGoalTypeCard() {
    final currentGoal = GoalType.fromString(_user?.goalType);

    return GestureDetector(
      onTap: () => _showGoalTypeDialog(),
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

  void _showActivityLevelDialog() {
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
              isSelected: _user?.activityLevel == level.value,
              onTap: () async {
                Navigator.pop(context);
                final updatedUser = _user?.copyWith(activityLevel: level.value);
                widget.onUserUpdated(updatedUser);
                await ApiService.updateProfile(activityLevel: level.value);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showGoalTypeDialog() {
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
              isSelected: _user?.goalType == goal.value,
              onTap: () async {
                Navigator.pop(context);
                final updatedUser = _user?.copyWith(goalType: goal.value);
                widget.onUserUpdated(updatedUser);
                await ApiService.updateProfile(goalType: goal.value);
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

  void _showEditNumberDialog(String type, String title, String unit, double? currentValue) {
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
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context);
                await _saveNumber(type, value);
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

  Future<void> _saveNumber(String type, double value) async {
    User? updatedUser;
    if (type == 'height') {
      updatedUser = _user?.copyWith(height: value);
    } else if (type == 'age') {
      updatedUser = _user?.copyWith(age: value.toInt());
    }
    widget.onUserUpdated(updatedUser);

    if (type == 'height') {
      await ApiService.updateProfile(height: value);
    } else {
      await ApiService.updateProfile(age: value.toInt());
    }
  }

  void _showEditWeightDialog(String type) {
    final isCurrentWeight = type == 'current';
    final currentValue = isCurrentWeight ? _user?.currentWeight : _user?.goalWeight;
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
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                Navigator.pop(context);
                await _saveWeight(type, value);
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

  Future<void> _saveWeight(String type, double value) async {
    User? updatedUser;
    if (type == 'current') {
      updatedUser = _user?.copyWith(currentWeight: value);
      widget.onUserUpdated(updatedUser);
      await ApiService.updateProfile(currentWeight: value);
    } else {
      updatedUser = _user?.copyWith(goalWeight: value);
      widget.onUserUpdated(updatedUser);
      await ApiService.updateProfile(goalWeight: value);
    }
  }

  Widget _buildSyncSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sync & Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.watch,
                iconColor: Colors.grey[800]!,
                title: 'Health Connect',
                subtitle: 'Sync calories & steps',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                showBorder: true,
              ),
              _buildSettingsItem(
                icon: Icons.notifications_active,
                iconColor: Colors.blue,
                title: 'Meal Reminders',
                subtitle: '8:00 AM, 12:00 PM, 6:00 PM',
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                showBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required bool showBorder,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: Colors.grey[100]!))
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
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
