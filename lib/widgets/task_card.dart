import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import 'task_form_modal.dart';

class TaskCard extends StatelessWidget {
  final TaskItem task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Proje bilgisi (Varsa)
    final project = taskProvider.getProjectById(task.projectId);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Görevi Sil'),
            content: Text('"${task.title}" görevini silmek istiyor musunuz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sil'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        taskProvider.deleteTask(task.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${task.title}" silindi'),
            action: SnackBarAction(
              label: 'Geri Al',
              onPressed: () => taskProvider.addTask(task),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141414) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: task.isCompleted
                ? Colors.transparent
                : (isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => TaskFormModal.show(context, taskToEdit: task),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Sade Yuvarlak Onay Kutusu
                  InkWell(
                    onTap: () => taskProvider.toggleTaskCompletion(task.id),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isCompleted
                            ? const Color(0xFF10B981)
                            : Colors.transparent,
                        border: Border.all(
                          color: task.isCompleted
                              ? const Color(0xFF10B981)
                              : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                          width: 2,
                        ),
                      ),
                      child: task.isCompleted
                          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Görev Başlığı ve Alt Bilgiler
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted
                                ? (isDark ? Colors.white38 : const Color(0xFF94A3B8))
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                        if (task.dueDate != null || (project != null && project.id != 'personal') || task.priority == TaskPriority.high) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Yüksek Öncelik Noktası
                              if (task.priority == TaskPriority.high) ...[
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                              // Tarih / Saat
                              if (task.dueDate != null) ...[
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: task.isOverdue ? Colors.red : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.isDueToday()
                                      ? 'Bugün ${DateFormat('HH:mm').format(task.dueDate!)}'
                                      : DateFormat('d MMM', 'tr_TR').format(task.dueDate!),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: task.isOverdue ? Colors.red : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              // Proje Rozeti (Örn: ALES Sınavı)
                              if (project != null && project.id != 'personal') ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: project.color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    project.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: project.color,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Yıldız (Günün En Önemlisi)
                  IconButton(
                    icon: Icon(
                      task.isTopPriority ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: task.isTopPriority ? Colors.amber : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => taskProvider.toggleTopPriority(task.id),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
