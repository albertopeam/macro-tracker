import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/macro_totals.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/services/tdee_calculator.dart';
import '../../../presentation/providers/providers.dart';

class GoalsTab extends ConsumerStatefulWidget {
  const GoalsTab({super.key});

  @override
  ConsumerState<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends ConsumerState<GoalsTab> {
  final _formKey = GlobalKey<FormState>();

  // Macro target controllers
  late TextEditingController _proteinCtrl;
  late TextEditingController _carbsCtrl;
  late TextEditingController _fatCtrl;
  late TextEditingController _caloriesCtrl;

  // Profile fields
  Sex _sex = Sex.male;
  ActivityLevel _activity = ActivityLevel.moderatelyActive;
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  bool _loaded = false;
  bool _profileLoaded = false;
  bool _saving = false;
  String? _selectedPreset; // 'maintenance' | 'cutting' | 'bulking'

  @override
  void dispose() {
    _proteinCtrl.dispose();
    _carbsCtrl.dispose();
    _fatCtrl.dispose();
    _caloriesCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _initControllers(MacroGoals goals, UserProfile? profile) {
    if (!_loaded) {
      _proteinCtrl = TextEditingController(text: goals.proteinG.round().toString());
      _carbsCtrl = TextEditingController(text: goals.carbsG.round().toString());
      _fatCtrl = TextEditingController(text: goals.fatG.round().toString());
      _caloriesCtrl = TextEditingController(text: goals.caloriesKcal.round().toString());
      _selectedPreset = goals.preset;
      _loaded = true;
    }
    if (!_profileLoaded && profile != null) {
      _sex = profile.sex;
      _activity = profile.activityLevel;
      _ageCtrl.text = profile.age.toString();
      _weightCtrl.text = profile.weightKg.toString();
      _heightCtrl.text = profile.heightCm.toString();
      _profileLoaded = true;
    }
  }

  UserProfile? _buildProfile() {
    final age = int.tryParse(_ageCtrl.text);
    final weight = double.tryParse(_weightCtrl.text);
    final height = double.tryParse(_heightCtrl.text);
    if (age == null || weight == null || height == null) return null;
    if (age <= 0 || weight <= 0 || height <= 0) return null;
    return UserProfile(
      sex: _sex,
      age: age,
      weightKg: weight,
      heightCm: height,
      activityLevel: _activity,
    );
  }

  void _applyPreset(MacroGoals Function(UserProfile) calculator, String presetKey) {
    final profile = _buildProfile();
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete your profile first')),
      );
      return;
    }
    final goals = calculator(profile);
    setState(() {
      _selectedPreset = presetKey;
      _proteinCtrl.text = goals.proteinG.round().toString();
      _carbsCtrl.text = goals.carbsG.round().toString();
      _fatCtrl.text = goals.fatG.round().toString();
      _caloriesCtrl.text = goals.caloriesKcal.round().toString();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final goals = MacroGoals(
      proteinG: double.parse(_proteinCtrl.text),
      carbsG: double.parse(_carbsCtrl.text),
      fatG: double.parse(_fatCtrl.text),
      caloriesKcal: double.parse(_caloriesCtrl.text),
      preset: _selectedPreset,
    );

    final profile = _buildProfile();
    if (profile != null) {
      await ref.read(profileProvider.notifier).save(profile);
    }
    await ref.read(goalsProvider.notifier).save(goals);

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Goals saved'), duration: Duration(seconds: 2)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalsProvider);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (goals) {
          _initControllers(goals, profileAsync.valueOrNull);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Profile',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  _ProfileSection(
                    sex: _sex,
                    activity: _activity,
                    ageCtrl: _ageCtrl,
                    weightCtrl: _weightCtrl,
                    heightCtrl: _heightCtrl,
                    onSexChanged: (s) => setState(() => _sex = s),
                    onActivityChanged: (a) => setState(() => _activity = a),
                  ),
                  const SizedBox(height: 28),
                  const Text('Daily macro targets',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  _MacroField(
                    label: 'Protein',
                    unit: 'g / day',
                    controller: _proteinCtrl,
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 16),
                  _MacroField(
                    label: 'Carbohydrates',
                    unit: 'g / day',
                    controller: _carbsCtrl,
                    color: const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 16),
                  _MacroField(
                    label: 'Fat',
                    unit: 'g / day',
                    controller: _fatCtrl,
                    color: const Color(0xFFFFA726),
                  ),
                  const SizedBox(height: 16),
                  _MacroField(
                    label: 'Calories',
                    unit: 'kcal / day',
                    controller: _caloriesCtrl,
                    color: const Color(0xFFEF5350),
                  ),
                  const SizedBox(height: 28),
                  const Text('Calculate from profile',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Maintenance'),
                        selected: _selectedPreset == 'maintenance',
                        onSelected: (_) => _applyPreset(TdeeCalculator.maintenance, 'maintenance'),
                      ),
                      ChoiceChip(
                        label: const Text('Cutting'),
                        selected: _selectedPreset == 'cutting',
                        onSelected: (_) => _applyPreset(TdeeCalculator.cutting, 'cutting'),
                      ),
                      ChoiceChip(
                        label: const Text('Bulking'),
                        selected: _selectedPreset == 'bulking',
                        onSelected: (_) => _applyPreset(TdeeCalculator.bulking, 'bulking'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Save goals'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final Sex sex;
  final ActivityLevel activity;
  final TextEditingController ageCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController heightCtrl;
  final void Function(Sex) onSexChanged;
  final void Function(ActivityLevel) onActivityChanged;

  const _ProfileSection({
    required this.sex,
    required this.activity,
    required this.ageCtrl,
    required this.weightCtrl,
    required this.heightCtrl,
    required this.onSexChanged,
    required this.onActivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Sex',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(width: 16),
            SegmentedButton<Sex>(
              segments: const [
                ButtonSegment(value: Sex.male, label: Text('Male')),
                ButtonSegment(value: Sex.female, label: Text('Female')),
              ],
              selected: {sex},
              onSelectionChanged: (s) => onSexChanged(s.first),
              showSelectedIcon: false,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ProfileField(
                label: 'Age',
                unit: 'yrs',
                controller: ageCtrl,
                isInt: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileField(
                label: 'Weight',
                unit: 'kg',
                controller: weightCtrl,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfileField(
                label: 'Height',
                unit: 'cm',
                controller: heightCtrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Activity level',
            border: OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ActivityLevel>(
              value: activity,
              isDense: true,
              isExpanded: true,
              items: ActivityLevel.values
                  .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
                  .toList(),
              onChanged: (a) {
                if (a != null) onActivityChanged(a);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final bool isInt;

  const _ProfileField({
    required this.label,
    required this.unit,
    required this.controller,
    this.isInt = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: isInt
          ? TextInputType.number
          : const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: isInt
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}

class _MacroField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final Color color;

  const _MacroField({
    required this.label,
    required this.unit,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border: const OutlineInputBorder(),
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color, width: 2),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        final n = double.tryParse(v);
        if (n == null || n <= 0) return 'Enter a positive number';
        return null;
      },
    );
  }
}
