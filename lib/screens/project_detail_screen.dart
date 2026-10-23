import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';

class ProjectDetailScreen extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  void _showEditProjectDialog() {
    final titleCtrl = TextEditingController(text: widget.project.name);
    int selectedColor = widget.project.colorValue;

    final colorOptions = [
      0xFF2563EB, // Mavi
      0xFF8B5CF6, // Mor
      0xFF10B981, // Yeşil
      0xFFF59E0B, // Turuncu
      0xFFEF4444, // Kırmızı
      0xFFEC4899, // Pembe
      0xFF06B6D4, // Camgöbeği
      0xFF64748B, // Gri
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Projeyi Düzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Proje Adı'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: colorOptions.map((c) {
                  final isSelected = selectedColor == c;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final name = titleCtrl.text.trim();
                if (name.isNotEmpty) {
                  widget.project.name = name;
                  widget.project.colorValue = selectedColor;
                  Provider.of<TaskProvider>(context, listen: false).updateProject(widget.project);
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectTasks = taskProvider.tasksForProject(widget.project.id);
    final completedCount = projectTasks.where((t) => t.isCompleted).length;
    final totalCount = projectTasks.length;
    final progress = taskProvider.projectProgress(widget.project.id);

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: widget.project.color.withOpacity(0.15),
              child: Icon(widget.project.icon, color: widget.project.color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.project.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (val) async {
              if (val == 'edit') {
                _showEditProjectDialog();
              } else if (val == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Projeyi Sil'),
                    content: Text('"${widget.project.name}" projesini ve içindeki tüm görevleri silmek istiyor musunuz?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sil'),
                      ),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  taskProvider.deleteProject(widget.project.id);
                  Navigator.pop(context);
                }
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'edit', child: Text('Projeyi Düzenle')),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Projeyi Sil', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Proje İlerleme Kartı
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141414) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF262626) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount / $totalCount konu tamamlandı',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      '%${(progress * 100).round()}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.project.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(widget.project.color),
                  ),
                ),
              ],
            ),
          ),

          // Görev Listesi
          Expanded(
            child: projectTasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.playlist_add_check_rounded,
                            size: 56,
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '"${widget.project.name}" projesinde henüz konu yok',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Yeni bir konu veya görev eklemek için aşağıdaki "+" butonuna dokunun.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 90),
                    itemCount: projectTasks.length,
                    itemBuilder: (ctx, index) {
                      return TaskCard(task: projectTasks[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => TaskFormModal.show(context, initialProjectId: widget.project.id),
        elevation: 3,
        backgroundColor: widget.project.color,
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }
}
