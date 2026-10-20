import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/spaced_repetition_service.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_wrapper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _reminderPatternController = TextEditingController();
  final TextEditingController _examNameController = TextEditingController();
  final TextEditingController _wakeController = TextEditingController();
  final TextEditingController _sleepController = TextEditingController();
  DateTime? _selectedExamDate;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncUserData();
  }

  void _syncUserData() {
    if (!_initialized) {
      final appState = context.read<AppState>();
      final userData = appState.userData;
      if (userData != null) {
        _nameController.text = userData.name;
        _reminderPatternController.text = userData.reminderPattern.join(', ');
        _wakeController.text = userData.wakeTime;
        _sleepController.text = userData.sleepTime;
        if (userData.exam != null) {
          _examNameController.text = userData.exam!.name ?? 'Exam';
          _selectedExamDate = DateTime.tryParse(userData.exam!.date);
        }
        _initialized = true;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _reminderPatternController.dispose();
    _examNameController.dispose();
    _wakeController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final appState = context.read<AppState>();
    if (_nameController.text.trim().isNotEmpty) {
      appState.updateUserName(_nameController.text.trim());
    }
    if (_wakeController.text.trim().isNotEmpty && _sleepController.text.trim().isNotEmpty) {
      appState.updateWakeSleepTimes(_wakeController.text.trim(), _sleepController.text.trim());
    }
    if (_selectedExamDate != null) {
      appState.updateExam(
        _examNameController.text.trim().isEmpty ? 'Exam' : _examNameController.text.trim(),
        _selectedExamDate!,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile saved successfully!'), behavior: SnackBarBehavior.floating),
    );
  }

  void _saveReminders() {
    final appState = context.read<AppState>();
    final pattern = SpacedRepetitionService.parsePatternString(_reminderPatternController.text);
    appState.updateReminderPattern(pattern);
    _reminderPatternController.text = pattern.join(', ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated review intervals: [${pattern.join(', ')}] days'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: AppColors.missed),
              SizedBox(width: 8),
              Text('Clear All Data?'),
            ],
          ),
          content: const Text(
            'This action is irreversible. All your study notes, subjects, schedules, and completion records will be completely deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.missed,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AppState>().resetAllData();
              },
              child: const Text('Delete Everything'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Student Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text("Display Name", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(hintText: "Your Name"),
                ),
                const SizedBox(height: 20),
                const Text("Routine Schedule (Time Management)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _wakeController,
                        decoration: const InputDecoration(
                          labelText: 'Waking Time',
                          hintText: 'e.g. 05:30',
                          prefixIcon: Icon(LucideIcons.clock, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _sleepController,
                        decoration: const InputDecoration(
                          labelText: 'Sleeping Time',
                          hintText: 'e.g. 22:30',
                          prefixIcon: Icon(LucideIcons.clock, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text("Target Exam Goal", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _examNameController,
                  decoration: const InputDecoration(hintText: "Exam Name (e.g. MCAT / Finals)"),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.calendar, color: AppColors.primary),
                  title: Text(
                    _selectedExamDate != null
                        ? DateFormat('MMMM d, yyyy').format(_selectedExamDate!)
                        : 'No exam date set',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedExamDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setState(() => _selectedExamDate = picked);
                      }
                    },
                    child: Text(_selectedExamDate == null ? 'Set Date' : 'Change'),
                  ),
                ),
                if (_selectedExamDate != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _selectedExamDate = null);
                      context.read<AppState>().clearExam();
                    },
                    icon: const Icon(LucideIcons.trash2, size: 14, color: AppColors.missed),
                    label: const Text('Remove exam goal', style: TextStyle(color: AppColors.missed)),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Profile Changes'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.repeat, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text("Spaced Repetition Engine", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Configure review intervals in days. Notes automatically generate reminder checkpoints based on these offsets.",
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                const Text("Interval Pattern (Days)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _reminderPatternController,
                  decoration: const InputDecoration(
                    hintText: "3, 6, 14, 30",
                    helperText: "Supports multipliers: e.g. '3, 6, 14, 30*12' (every 30 days for 12 months)",
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text("Default: 3, 6, 14, 30"),
                      onPressed: () {
                        setState(() => _reminderPatternController.text = "3, 6, 14, 30");
                      },
                    ),
                    ActionChip(
                      label: const Text("Intensive: 1, 3, 7, 14, 30"),
                      onPressed: () {
                        setState(() => _reminderPatternController.text = "1, 3, 7, 14, 30");
                      },
                    ),
                    ActionChip(
                      label: const Text("Annual: 3, 7, 30, 30*12"),
                      onPressed: () {
                        setState(() => _reminderPatternController.text = "3, 7, 30, 30*12");
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveReminders,
                    child: const Text('Update Interval Engine'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTab() {
    final appState = context.watch<AppState>();
    final userData = appState.userData;
    final totalNotes = userData?.subjects.fold<int>(0, (acc, s) => acc + s.notes.length) ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Storage & Synchronization", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(LucideIcons.database, color: AppColors.primary),
                  title: const Text("Local Cache"),
                  subtitle: Text("${userData?.subjects.length ?? 0} Subjects • $totalNotes Notes • ${userData?.todos?.length ?? 0} Todos"),
                ),
                const Divider(),
                const SizedBox(height: 12),
                const Text(
                  "Danger Zone",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.missed),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Permanently erase all local study data, notes, and habits to start fresh with onboarding.",
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.missed,
                    side: const BorderSide(color: AppColors.missed),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _confirmClearData,
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  label: const Text('Clear All Data & Reset App'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.sparkles, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Study Smart",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.foreground),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Version 1.0.0 (Flutter Recreation)",
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Based on Hermann Ebbinghaus's Forgetting Curve research, Study Smart schedules reviews at strategically increasing intervals right when memory decay begins, cementing information into long-term recall.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.foreground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncUserData();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: ResponsiveWrapper(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                dividerHeight: 0,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.foreground,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: "Profile"),
                  Tab(text: "Reminders"),
                  Tab(text: "Data"),
                  Tab(text: "About"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(),
                _buildRemindersTab(),
                _buildDataTab(),
                _buildAboutTab(),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
