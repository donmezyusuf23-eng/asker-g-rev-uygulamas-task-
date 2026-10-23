import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_modal.dart';

enum TaskSortOption { dateAsc, priorityDesc, titleAsc }

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _statusTabIndex = 0; // 0: Tümü, 1: Bekleyen, 2: Tamamlanan
  TaskSortOption _sortOption = TaskSortOption.dateAsc;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Temel filtrelenmiş liste
    var tasks = List<TaskItem>.from(taskProvider.filteredTasks);

    // Tamamlanma durumu sekmesi filtresi
    if (_statusTabIndex == 1) {
      tasks = tasks.where((t) => !t.isCompleted).toList();
    } else if (_statusTabIndex == 2) {
      tasks = tasks.where((t) => t.isCompleted).toList();
    }

    // Sıralama
    tasks.sort((a, b) {
      switch (_sortOption) {
        case TaskSortOption.dateAsc:
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        case TaskSortOption.priorityDesc:
          return b.priority.index.compareTo(a.priority.index);
        case TaskSortOption.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tüm Görevler'),
        actions: [
          PopupMenuButton<TaskSortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sırala',
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: TaskSortOption.dateAsc,
                child: Text('Tarihe Göre Sırala'),
              ),
              const PopupMenuItem(
                value: TaskSortOption.priorityDesc,
                child: Text('Önceliğe Göre Sırala'),
              ),
              const PopupMenuItem(
                value: TaskSortOption.titleAsc,
                child: Text('Ada Göre Sırala (A-Z)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => taskProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Görevlerde ara...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          taskProvider.setSearchQuery('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
            ),
          ),

          // Durum Sekmeleri (Tümü / Bekleyen / Tamamlanan)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Tümü')),
                ButtonSegment(value: 1, label: Text('Bekleyen')),
                ButtonSegment(value: 2, label: Text('Tamamlanan')),
              ],
              selected: {_statusTabIndex},
              onSelectionChanged: (val) {
                setState(() => _statusTabIndex = val.first);
              },
            ),
          ),

          // Kategori Filtre Çipleri
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Hepsi'),
                  selected: taskProvider.selectedCategory == null,
                  onSelected: (selected) {
                    if (selected) taskProvider.setCategoryFilter(null);
                  },
                ),
                const SizedBox(width: 6),
                ...taskProvider.categories.map((cat) {
                  final isSelected = taskProvider.selectedCategory == cat.name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : cat.color),
                      label: Text(cat.name),
                      selected: isSelected,
                      selectedColor: cat.color,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                      onSelected: (selected) {
                        taskProvider.setCategoryFilter(selected ? cat.name : null);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Sonuç Sayacı & Filtre Temizleme
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tasks.length} Görev Listeleniyor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                if (taskProvider.selectedCategory != null ||
                    taskProvider.selectedPriority != null ||
                    _searchCtrl.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      taskProvider.clearFilters();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Filtreleri Temizle', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),

          // Görev Listesi
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kriterlere uygun görev bulunamadı',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Farklı bir arama yapabilir veya yeni bir görev ekleyebilirsiniz.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: tasks.length,
                    itemBuilder: (ctx, index) {
                      return TaskCard(task: tasks[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => TaskFormModal.show(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
