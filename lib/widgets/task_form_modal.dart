import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskFormModal extends StatefulWidget {
  final TaskItem? taskToEdit;
  final String? initialProjectId;

  const TaskFormModal({super.key, this.taskToEdit, this.initialProjectId});

  static void show(BuildContext context, {TaskItem? taskToEdit, String? initialProjectId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: TaskFormModal(
          taskToEdit: taskToEdit,
          initialProjectId: initialProjectId,
        ),
      ),
    );
  }

  @override
  State<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends State<TaskFormModal> {
  final _uuid = const Uuid();
  late TextEditingController _titleController;
  late TextEditingController _descController;

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  TaskPriority _priority = TaskPriority.medium;
  String _selectedProjectId = 'personal';
  bool _isTopPriority = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.taskToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _descController = TextEditingController(text: edit?.description ?? '');

    if (edit != null) {
      _dueDate = edit.dueDate;
      if (edit.dueDate != null) {
        _dueTime = TimeOfDay(hour: edit.dueDate!.hour, minute: edit.dueDate!.minute);
      }
      _priority = edit.priority;
      _selectedProjectId = edit.projectId;
      _isTopPriority = edit.isTopPriority;
    } else {
      _selectedProjectId = widget.initialProjectId ?? 'personal';
      _dueDate = DateTime.now();
      _dueTime = const TimeOfDay(hour: 12, minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _saveTask() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir görev başlığı yazın.')),
      );
      return;
    }

    DateTime? combinedDueDate;
    if (_dueDate != null) {
      final hour = _dueTime?.hour ?? 12;
      final minute = _dueTime?.minute ?? 0;
      combinedDueDate = DateTime(_dueDate!.year, _dueDate!.month, _dueDate!.day, hour, minute);
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Seçilen projeyi doğrula
    final project = taskProvider.getProjectById(_selectedProjectId);
    final categoryName = project?.name ?? 'Kişisel';

    try {
      if (widget.taskToEdit != null) {
        final updated = widget.taskToEdit!.copyWith(
          title: title,
          description: _descController.text.trim(),
          dueDate: combinedDueDate,
          priority: _priority,
          projectId: _selectedProjectId,
          category: categoryName,
          isTopPriority: _isTopPriority,
        );
        taskProvider.updateTask(updated);
      } else {
        final newTask = TaskItem(
          id: _uuid.v4(),
          title: title,
          description: _descController.text.trim(),
          dueDate: combinedDueDate,
          priority: _priority,
          projectId: _selectedProjectId,
          category: categoryName,
          isTopPriority: _isTopPriority,
        );
        taskProvider.addTask(newTask);
      }

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt sırasında hata oluştu: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final taskProvider = Provider.of<TaskProvider>(context);

    // Eğer seçili proje listede yoksa ilkini seç
    if (taskProvider.projects.isNotEmpty &&
        !taskProvider.projects.any((p) => p.id == _selectedProjectId)) {
      _selectedProjectId = taskProvider.projects.first.id;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Üst Tutamaç
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.taskToEdit == null ? 'Yeni Görev Ekle' : 'Görevi Düzenle',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Görev Başlığı
            TextField(
              controller: _titleController,
              autofocus: widget.taskToEdit == null,
              decoration: InputDecoration(
                hintText: 'Görev adı...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Proje / Liste Seçimi (Varsa)
            if (taskProvider.projects.isNotEmpty) ...[
              const Text(
                'Proje / Liste',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: taskProvider.projects.map((proj) {
                    final isSelected = _selectedProjectId == proj.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        avatar: Icon(proj.icon, size: 14, color: isSelected ? Colors.white : proj.color),
                        label: Text(proj.name),
                        selectedColor: proj.color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          setState(() => _selectedProjectId = proj.id);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Tarih ve Saat Seçimi
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      _dueDate == null
                          ? 'Tarih Seç'
                          : DateFormat('d MMM', 'tr_TR').format(_dueDate!),
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _dueDate = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(
                      _dueTime == null ? 'Saat Seç' : _dueTime!.format(context),
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _dueTime ?? TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() => _dueTime = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Öncelik Seviyesi
            const Text(
              'Öncelik',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildPriorityChip(TaskPriority.low, 'Düşük', const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildPriorityChip(TaskPriority.medium, 'Orta', const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _buildPriorityChip(TaskPriority.high, 'Yüksek', const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 12),

            // Günün En Önemli Görevlerine Ekle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Günün En Önemli Görevlerine Ekle', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              value: _isTopPriority,
              onChanged: (val) {
                setState(() => _isTopPriority = val);
              },
            ),
            const SizedBox(height: 10),

            // Notlar (Opsiyonel)
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Açıklama / notlar (opsiyonel)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Kaydet Butonu
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _saveTask,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  widget.taskToEdit == null ? 'Görevi Kaydet' : 'Değişiklikleri Kaydet',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority priority, String label, Color color) {
    final isSelected = _priority == priority;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _priority = priority),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : null,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
