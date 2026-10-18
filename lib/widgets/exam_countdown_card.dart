import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_icons.dart';
import '../models/exam.dart';
import '../theme/app_theme.dart';

class ExamCountdownCard extends StatefulWidget {
  final Exam exam;

  const ExamCountdownCard({super.key, required this.exam});

  @override
  State<ExamCountdownCard> createState() => _ExamCountdownCardState();
}

class _ExamCountdownCardState extends State<ExamCountdownCard> {
  Timer? _timer;
  Duration _difference = Duration.zero;
  bool _isPast = false;

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTime());
  }

  @override
  void didUpdateWidget(covariant ExamCountdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exam.date != widget.exam.date) {
      _calculateTime();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTime() {
    final examDate = DateTime.tryParse(widget.exam.date);
    if (examDate == null) return;

    final now = DateTime.now();
    if (examDate.isBefore(now)) {
      if (mounted) {
        setState(() {
          _isPast = true;
          _difference = Duration.zero;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isPast = false;
          _difference = examDate.difference(now);
        });
      }
    }
  }

  Widget _buildTimeBox(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _difference.inDays;
    final hours = _difference.inHours % 24;
    final minutes = _difference.inMinutes % 60;
    final seconds = _difference.inSeconds % 60;
    final years = (days / 365).floor();
    final remainingDays = days % 365;
    final months = (remainingDays / 30).floor();
    final displayDays = remainingDays % 30;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7E50FF), Color(0xFF4318FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7E50FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.graduationCap, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exam.name ?? 'Target Exam',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _isPast ? 'Exam passed' : 'Countdown to exam day',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isPast)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.completed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Active Goal',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (_isPast)
            const Center(
              child: Text(
                'Good luck on your future academic endeavors!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (years > 0) _buildTimeBox(years.toString(), 'YRS'),
                _buildTimeBox(months.toString().padLeft(2, '0'), 'MON'),
                _buildTimeBox(displayDays.toString().padLeft(2, '0'), 'DAYS'),
                _buildTimeBox(hours.toString().padLeft(2, '0'), 'HRS'),
                _buildTimeBox(minutes.toString().padLeft(2, '0'), 'MIN'),
                _buildTimeBox(seconds.toString().padLeft(2, '0'), 'SEC'),
              ],
            ),
        ],
      ),
    );
  }
}
