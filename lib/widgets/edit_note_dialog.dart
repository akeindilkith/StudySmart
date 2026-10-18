import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../models/subject.dart';
import '../providers/app_state.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

class EditNoteDialog extends StatefulWidget {
  final Note note;
  final Subject subject;

  const EditNoteDialog({
    super.key,
    required this.note,
    required this.subject,
  });

  @override
  State<EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<EditNoteDialog> {
  late TextEditingController _contentController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note.content);
    _selectedDate = DateTime.tryParse(widget.note.date) ?? DateTime.now();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final formattedDate = DateFormat('MMM d, yyyy').format(_selectedDate);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.pencil, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          const Text('Edit Study Note', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: ${widget.subject.name}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
            const SizedBox(height: 16),
            const Text('Note Content', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            TextField(
              controller: _contentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter study note...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Study Date (Recalculates Review Days)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 16, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    const Icon(LucideIcons.chevronDown, size: 16, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () async {
            await appState.deleteNoteById(widget.note.id);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note deleted successfully')),
              );
            }
          },
          icon: const Icon(LucideIcons.trash2, size: 16),
          label: const Text('Delete'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () async {
            final content = _contentController.text.trim();
            if (content.isNotEmpty) {
              await appState.updateNote(
                noteId: widget.note.id,
                newContent: content,
                newStudyDate: _selectedDate,
              );
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note updated & review days recalculated!')),
                );
              }
            }
          },
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
