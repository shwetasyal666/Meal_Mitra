import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mealmitra/features/auth/data/auth_repository.dart';
import 'package:mealmitra/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mealmitra/features/profile/data/profile_repository.dart';
import 'package:mealmitra/features/profile/domain/daily_calorie_target_calculator.dart';
import 'package:mealmitra/features/profile/domain/user_profile.dart';
import 'package:mealmitra/core/utils/unit_converter.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  double _height = 170;
  double _weight = 70;
  ProfileGoal _goal = ProfileGoal.lose;
  ActivityLevel _activity = ActivityLevel.moderate;
  String _gender = 'Male';
  bool _useMetricHeight = true;
  bool _useMetricWeight = true;
  String _cuisinePreference = 'Any';
  String _healthFocus = 'General Wellness';
  String? _profilePic;
  bool _initialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback or listen to handle initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final profile = ref.read(currentProfileProvider).value;
    if (profile != null) {
      setState(() {
        _name.text = profile.displayName;
        _age.text = profile.age.toString();
        _height = profile.heightCm;
        _weight = profile.weightKg;
        _gender = profile.gender;
        _goal = profile.goal;
        _activity = profile.activityLevel;
        _useMetricHeight = profile.useMetricHeight;
        _useMetricWeight = profile.useMetricWeight;
        _cuisinePreference = profile.cuisinePreference;
        _healthFocus = profile.healthFocus;
        _profilePic = profile.profilePictureUrl;
      });
    }
  }

  void _updateFromProfile(UserProfile profile) {
    _name.text = profile.displayName;
    _age.text = profile.age.toString();
    _height = profile.heightCm;
    _weight = profile.weightKg;
    _gender = profile.gender;
    _goal = profile.goal;
    _activity = profile.activityLevel;
    _useMetricHeight = profile.useMetricHeight;
    _useMetricWeight = profile.useMetricWeight;
    _cuisinePreference = profile.cuisinePreference;
    _healthFocus = profile.healthFocus;
    _profilePic = profile.profilePictureUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final uid = ref.read(authStateProvider).value;
      if (uid == null) return;

      final age = int.parse(_age.text);
      final target = DailyCalorieTargetCalculator.calculate(
        age: age,
        heightCm: _height,
        weightKg: _weight,
        gender: _gender,
        goal: _goal,
        activityLevel: _activity,
      );

      final profile = UserProfile(
        uid: uid,
        displayName: _name.text.trim(),
        gender: _gender,
        age: age,
        heightCm: _height,
        weightKg: _weight,
        goal: _goal,
        activityLevel: _activity,
        dailyCalorieTarget: target,
        healthConditions: [],
        useMetricHeight: _useMetricHeight,
        useMetricWeight: _useMetricWeight,
        cuisinePreference: _cuisinePreference,
        healthFocus: _healthFocus,
        profilePictureUrl: _profilePic,
      );

      await ref.read(profileRepositoryProvider).saveProfile(profile);
      ref.invalidate(currentProfileProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Color(0xFF027B3D)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(currentProfileProvider);

    // Listen for profile changes to update local state if needed (e.g. after initial load)
    ref.listen(currentProfileProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        if (!_initialized) {
          setState(() {
            _updateFromProfile(next.value!);
            _initialized = true;
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF027B3D))),
          error: (err, stack) => Center(child: Text('Error loading profile: $err')),
          data: (profile) {
            // If profile is null, it means onboarding was not finished
            if (profile == null) {
              return const Center(child: Text('Please complete onboarding first.'));
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 32),
                  Text(
                    "Personal Metrics",
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 34,
                    ),
                  ),
                  const Text(
                    'Data depth ensures editorial precision.',
                    style: TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle('THE METRICS'),
                  const SizedBox(height: 16),
                  _buildMetricItem(context, LucideIcons.user, 'Display Name', _name.text, isEditable: true, onTap: () => _showEditSheet('name')),
                  _buildMetricItem(context, LucideIcons.cake, 'Age', '${_age.text} Years', isEditable: true, onTap: () => _showEditSheet('age')),
                  _buildMetricItem(context, LucideIcons.ruler, 'Height', UnitConverter.formatHeight(_height.round(), _useMetricHeight), isEditable: true, onTap: () => _showEditSheet('height')),
                  _buildMetricItem(context, LucideIcons.weight, 'Weight', UnitConverter.formatWeight(_weight.round(), _useMetricWeight), isEditable: true, onTap: () => _showEditSheet('weight')),
                  _buildMetricItem(context, LucideIcons.users, 'Gender', _gender, isEditable: true, onTap: () => _showEditSheet('gender')),
                  _buildMetricItem(context, LucideIcons.ruler, 'Metric Height', _useMetricHeight ? 'Yes' : 'No', isEditable: true, onTap: () => setState(() => _useMetricHeight = !_useMetricHeight)),
                  _buildMetricItem(context, LucideIcons.weight, 'Metric Weight', _useMetricWeight ? 'Yes' : 'No', isEditable: true, onTap: () => setState(() => _useMetricWeight = !_useMetricWeight)),

                  const SizedBox(height: 32),
                  _buildSectionTitle('THE LIFESTYLE'),
                  const SizedBox(height: 16),
                  _buildActivityCard(context),

                  const SizedBox(height: 32),
                  _buildSectionTitle('THE GOAL'),
                  const SizedBox(height: 16),
                  _buildGoalSelector(context),

                  const SizedBox(height: 32),
                  _buildSectionTitle('REGIONAL PREFERENCES'),
                  const SizedBox(height: 16),
                  _buildPreferenceItem(context, 'Cuisine Type', _cuisinePreference, LucideIcons.mapPin, onTap: () => _showEditSheet('cuisine')),
                  _buildPreferenceItem(context, 'Health Focus', _healthFocus, LucideIcons.heartPulse, onTap: () => _showEditSheet('focus')),

                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF027B3D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Editorial Data'),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
          icon: const Icon(LucideIcons.logOut, color: Colors.black45, size: 20),
        ),
        const Spacer(),
        Text(
          'The Vitality Editorial',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF027B3D),
            fontSize: 18,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () async {
            // Placeholder for image picker upload logic
            // E.g., await pickImage(), uploadToCloudinary(), set _profilePic
          },
          child: CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(_profilePic ?? 'https://api.dicebear.com/7.x/avataaars/png?seed=Felix'),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black38,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, IconData icon, String label, String value, {bool isEditable = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: isEditable ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFFAF9F6), shape: BoxShape.circle),
              child: Icon(icon, size: 18, color: Colors.black54),
            ),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            Text(value, style: const TextStyle(color: Colors.black45, fontWeight: FontWeight.w600, fontSize: 14)),
            if (isEditable) ...[
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronRight, size: 16, color: Colors.black26),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF027B3D),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Energy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                Text('${_activity.name.toUpperCase()} Activity Level', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditSheet('activity'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: const Text('Change', style: TextStyle(color: Color(0xFF027B3D), fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(String field) {
    final title = field[0].toUpperCase() + field.substring(1);
    final tempController = TextEditingController();
    double tempSliderValue = 0;

    if (field == 'name') tempController.text = _name.text;
    if (field == 'age') tempController.text = _age.text;
    if (field == 'height') tempSliderValue = _height;
    if (field == 'weight') tempSliderValue = _weight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 40),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Update $title', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, size: 20)),
                ],
              ),
              const SizedBox(height: 24),
              if (field == 'name' || field == 'age')
                TextField(
                  controller: tempController,
                  autofocus: true,
                  keyboardType: field == 'age' ? TextInputType.number : TextInputType.text,
                  decoration: InputDecoration(
                    hintText: 'Enter your $field',
                    filled: true,
                    fillColor: const Color(0xFFFAF9F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                )
              else if (field == 'height' || field == 'weight')
                Column(
                  children: [
                    Text(
                      field == 'height' 
                          ? UnitConverter.formatHeight(tempSliderValue.round(), _useMetricHeight)
                          : UnitConverter.formatWeight(tempSliderValue.round(), _useMetricWeight), 
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF027B3D))
                    ),
                    Slider(
                      value: tempSliderValue,
                      min: field == 'height' ? 100 : 30,
                      max: field == 'height' ? 250 : 200,
                      activeColor: const Color(0xFF027B3D),
                      onChanged: (v) => setSheetState(() => tempSliderValue = v),
                    ),
                  ],
                )
              else if (field == 'activity')
                RadioGroup<ActivityLevel>(
                  groupValue: _activity,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _activity = v);
                      Navigator.pop(context);
                    }
                  },
                  child: Column(
                    children: ActivityLevel.values
                        .map((level) => RadioListTile<ActivityLevel>(
                              title: Text(level.name.toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              value: level,
                              activeColor: const Color(0xFF027B3D),
                            ))
                        .toList(),
                  ),
                )
              else if (field == 'gender')
                RadioGroup<String>(
                  groupValue: _gender,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _gender = v);
                      Navigator.pop(context);
                    }
                  },
                  child: Column(
                    children: ['Male', 'Female']
                        .map((g) => RadioListTile<String>(
                              title: Text(g,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              value: g,
                              activeColor: const Color(0xFF027B3D),
                            ))
                        .toList(),
                  ),
                )
              else if (field == 'cuisine')
                RadioGroup<String>(
                  groupValue: _cuisinePreference,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _cuisinePreference = v);
                      Navigator.pop(context);
                    }
                  },
                  child: Column(
                    children: ['Any', 'North Indian', 'South Indian', 'Continental', 'Vegan', 'Keto']
                        .map((c) => RadioListTile<String>(
                              title: Text(c,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              value: c,
                              activeColor: const Color(0xFF027B3D),
                            ))
                        .toList(),
                  ),
                )
              else if (field == 'focus')
                RadioGroup<String>(
                  groupValue: _healthFocus,
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _healthFocus = v);
                      Navigator.pop(context);
                    }
                  },
                  child: Column(
                    children: ['General Wellness', 'Fat Loss', 'Muscle Gain', 'Diabetic Friendly', 'Heart Health']
                        .map((f) => RadioListTile<String>(
                              title: Text(f,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800)),
                              value: f,
                              activeColor: const Color(0xFF027B3D),
                            ))
                        .toList(),
                  ),
                ),
              const SizedBox(height: 32),
              if (field != 'activity' && field != 'gender' && field != 'cuisine' && field != 'focus')
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (field == 'name') _name.text = tempController.text;
                      if (field == 'age') _age.text = tempController.text;
                      if (field == 'height') _height = tempSliderValue;
                      if (field == 'weight') _weight = tempSliderValue;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF027B3D),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Save Changes'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalSelector(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildGoalCard('Lose Weight', _goal == ProfileGoal.lose, () => setState(() => _goal = ProfileGoal.lose))),
        const SizedBox(width: 8),
        Expanded(child: _buildGoalCard('Keep Fit', _goal == ProfileGoal.maintain, () => setState(() => _goal = ProfileGoal.maintain))),
        const SizedBox(width: 8),
        Expanded(child: _buildGoalCard('Gain Mass', _goal == ProfileGoal.gain, () => setState(() => _goal = ProfileGoal.gain))),
      ],
    );
  }

  Widget _buildGoalCard(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE7F3ED) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? const Color(0xFF027B3D).withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04)),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.target, color: isSelected ? const Color(0xFF027B3D) : Colors.black26),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isSelected ? const Color(0xFF0D3B2E) : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem(BuildContext context, String label, String value, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF027B3D)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w800)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
            const Spacer(),
            const Icon(LucideIcons.chevronRight, size: 16, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}
