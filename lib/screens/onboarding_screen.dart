import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_icons.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

const List<String> kDaysOfWeek = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday'
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form states
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _subjectInputController = TextEditingController();
  final List<String> _subjects = ['Mathematics', 'Physics', 'History'];
  final Map<String, List<String>> _subjectDays = {
    'Mathematics': ['Monday', 'Wednesday', 'Friday'],
    'Physics': ['Tuesday', 'Thursday'],
    'History': ['Saturday'],
  };
  DateTime? _selectedExamDate;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _subjectInputController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1 && _subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one subject to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _finishOnboarding() {
    if (_subjects.isEmpty) {
      _subjects.add('General Studies');
      _subjectDays['General Studies'] = ['Monday', 'Wednesday', 'Friday'];
    }
    final appState = context.read<AppState>();
    appState.completeOnboarding(
      name: _nameController.text.trim().isEmpty ? 'Student' : _nameController.text.trim(),
      subjectNames: _subjects,
      subjectDays: _subjectDays,
      examDate: _selectedExamDate,
    );
  }

  void _addSubject() {
    final text = _subjectInputController.text.trim();
    if (text.isNotEmpty && !_subjects.contains(text)) {
      setState(() {
        _subjects.add(text);
        _subjectDays[text] = ['Monday', 'Wednesday'];
        _subjectInputController.clear();
      });
    }
  }

  void _removeSubject(String subject) {
    setState(() {
      _subjects.remove(subject);
      _subjectDays.remove(subject);
    });
  }

  // Step 1: Name Input
  Widget _buildStep1() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.user, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        const Text(
          "Welcome to Study Smart! 👋",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Let's personalize your experience. What should we call you?",
          style: TextStyle(fontSize: 15, color: AppColors.textMuted),
        ),
        const SizedBox(height: 28),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: "Enter your name (e.g. Alex)",
            prefixIcon: Icon(LucideIcons.userCheck, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  // Step 2: Subject Tagging
  Widget _buildStep2() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.bookOpen, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        const Text(
          "What are you studying? 📚",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Add your subjects or courses to build custom review schedules.",
          style: TextStyle(fontSize: 15, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _subjectInputController,
                onSubmitted: (_) => _addSubject(),
                decoration: const InputDecoration(
                  hintText: "Add a subject...",
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
              onPressed: _addSubject,
              child: const Icon(LucideIcons.plus, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _subjects.map((sub) {
            return Chip(
              label: Text(sub, style: const TextStyle(fontWeight: FontWeight.w600)),
              deleteIcon: const Icon(LucideIcons.x, size: 16),
              onDeleted: () => _removeSubject(sub),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          }).toList(),
        ),
      ],
    );
  }

  // Step 3: Weekly Frequency Mapping
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.calendarDays, size: 24, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Study Frequency 🗓️",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Select which days you study each subject.",
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: _subjects.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final subject = _subjects[index];
              final currentDays = _subjectDays[subject] ?? [];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: kDaysOfWeek.map((day) {
                        final isSelected = currentDays.contains(day);
                        return FilterChip(
                          label: Text(
                            day.substring(0, 3),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : AppColors.foreground,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF3F4F6),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                currentDays.add(day);
                              } else {
                                currentDays.remove(day);
                              }
                              _subjectDays[subject] = currentDays;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Step 4: Optional Exam Date Picker
  Widget _buildStep4() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.graduationCap, size: 36, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        const Text(
          "Upcoming Exam? 🎯",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.foreground,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Set an exam date to unlock the countdown tracker and prioritize reviews.",
          style: TextStyle(fontSize: 15, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.calendar, color: AppColors.primary),
                title: Text(
                  _selectedExamDate != null
                      ? DateFormat('MMMM d, yyyy').format(_selectedExamDate!)
                      : 'No date selected',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Target exam date'),
                trailing: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedExamDate = picked;
                      });
                    }
                  },
                  child: Text(_selectedExamDate == null ? 'Select Date' : 'Change'),
                ),
              ),
              if (_selectedExamDate != null)
                TextButton(
                  onPressed: () => setState(() => _selectedExamDate = null),
                  child: const Text('Clear date (Optional)', style: TextStyle(color: AppColors.textMuted)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Progress Bar
              Row(
                children: List.generate(4, (index) {
                  return Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _currentStep
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              // Page View
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (step) => setState(() => _currentStep = step),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                  ],
                ),
              ),
              // Bottom Controls
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      TextButton.icon(
                        onPressed: _prevStep,
                        icon: const Icon(LucideIcons.chevronLeft, size: 18),
                        label: const Text('Back'),
                      )
                    else
                      const SizedBox(width: 80),
                    ElevatedButton(
                      onPressed: _nextStep,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_currentStep == 3 ? 'Get Started' : 'Next'),
                          const SizedBox(width: 8),
                          Icon(
                            _currentStep == 3 ? LucideIcons.rocket : LucideIcons.chevronRight,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
