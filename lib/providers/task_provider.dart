import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../models/project_model.dart';
import '../services/storage_service.dart';
import '../services/smart_task_parser.dart';

class TaskProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<TaskItem> _tasks = [];
  List<ProjectModel> _projects = [];
  List<TaskCategory> _categories = [];
  int _dailyGoal = 5;
  int _streakCount = 0;
  bool _isLoading = true;

  // Filtreler
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedProjectId;
  TaskPriority? _selectedPriority;

  // Getter'lar
  bool get isLoading => _isLoading;
  List<TaskItem> get allTasks => List.unmodifiable(_tasks);
  List<ProjectModel> get projects => List.unmodifiable(_projects);
  List<TaskCategory> get categories => List.unmodifiable(_categories);
  int get dailyGoal => _dailyGoal;
  int get streakCount => _streakCount;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  String? get selectedProjectId => _selectedProjectId;
  TaskPriority? get selectedPriority => _selectedPriority;

  TaskProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    _tasks = await StorageService.loadTasks();
    _projects = await StorageService.loadProjects();
    _categories = await StorageService.loadCategories();
    // Eski varsayılan kalabalık kategorileri temizle
    _categories.removeWhere((c) => [
      'personal', 'work', 'school', 'health', 'sports', 'shopping', 'other'
    ].contains(c.id));
    await StorageService.saveCategories(_categories);
    _dailyGoal = await StorageService.loadDailyGoal();
    _streakCount = await StorageService.loadStreakCount();

    // Günlük seri (streak) kontrolü
    _checkDailyStreak();

    _isLoading = false;
    notifyListeners();
  }

  // --- PROJE İŞLEMLERİ ---

  ProjectModel? getProjectById(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<TaskItem> tasksForProject(String projectId) {
    return _tasks.where((t) => t.projectId == projectId).toList();
  }

  double projectProgress(String projectId) {
    final pTasks = tasksForProject(projectId);
    if (pTasks.isEmpty) return 0.0;
    final completed = pTasks.where((t) => t.isCompleted).length;
    return (completed / pTasks.length).clamp(0.0, 1.0);
  }

  Future<ProjectModel> addProject(String name, int iconCode, int colorValue) async {
    final project = ProjectModel(
      id: _uuid.v4(),
      name: name,
      iconCode: iconCode,
      colorValue: colorValue,
    );
    _projects.add(project);
    await StorageService.saveProjects(_projects);
    notifyListeners();
    return project;
  }

  Future<void> updateProject(ProjectModel updated) async {
    final index = _projects.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _projects[index] = updated;
      await StorageService.saveProjects(_projects);
      notifyListeners();
    }
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    // İlgili projedeki görevleri sil veya kişisel'e taşı
    _tasks.removeWhere((t) => t.projectId == id);
    await StorageService.saveProjects(_projects);
    await _persist();
    notifyListeners();
  }

  /// Projeye hızlı görev ekle
  Future<TaskItem> addTaskToProject(String projectId, String title) async {
    final project = getProjectById(projectId);
    final task = TaskItem(
      id: _uuid.v4(),
      title: title.trim(),
      projectId: projectId,
      category: project?.name ?? 'Genel',
      dueDate: DateTime.now(),
    );
    await addTask(task);
    return task;
  }

  // --- HESAPLANAN ÖZELLİKLER VE LİSTELER ---

  /// Bugün yapılması gereken veya bugün eklenmiş görevler
  List<TaskItem> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.dueDate != null) {
        return t.dueDate!.year == now.year &&
            t.dueDate!.month == now.month &&
            t.dueDate!.day == now.day;
      }
      return t.createdAt.year == now.year &&
          t.createdAt.month == now.month &&
          t.createdAt.day == now.day;
    }).toList();
  }

  /// Günün En Önemli 3 Görevi (Top 3)
  List<TaskItem> get topThreeTasks {
    final today = todayTasks;
    final topList = today.where((t) => t.isTopPriority).toList();
    if (topList.length >= 3) {
      return topList.take(3).toList();
    }
    final remaining = today
        .where((t) => !topList.contains(t) && t.priority == TaskPriority.high)
        .toList();
    final combined = [...topList, ...remaining];
    return combined.take(3).toList();
  }

  /// Gecikmiş görevler
  List<TaskItem> get overdueTasks {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      return t.dueDate!.isBefore(startOfToday);
    }).toList();
  }

  /// Belirli bir tarihteki görevler (Takvim için)
  List<TaskItem> tasksForDate(DateTime date) {
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == date.year &&
          t.dueDate!.month == date.month &&
          t.dueDate!.day == date.day;
    }).toList();
  }

  /// Bugün tamamlanan görev sayısı
  int get todayCompletedCount {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      return t.completedAt!.year == now.year &&
          t.completedAt!.month == now.month &&
          t.completedAt!.day == now.day;
    }).toList().length;
  }

  /// Günlük ilerleme yüzdesi (0.0 - 1.0)
  double get dailyProgress {
    final today = todayTasks;
    if (today.isEmpty) {
      if (todayCompletedCount > 0 && _dailyGoal > 0) {
        return (todayCompletedCount / _dailyGoal).clamp(0.0, 1.0);
      }
      return 0.0;
    }
    final completed = today.where((t) => t.isCompleted).length;
    return (completed / today.length).clamp(0.0, 1.0);
  }

  /// Filtrelenmiş Tüm Görevler
  List<TaskItem> get filteredTasks {
    return _tasks.where((task) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(q);
        final matchesDesc = task.description.toLowerCase().contains(q);
        if (!matchesTitle && !matchesDesc) return false;
      }
      if (_selectedProjectId != null && task.projectId != _selectedProjectId) {
        return false;
      }
      if (_selectedCategory != null && task.category != _selectedCategory) {
        return false;
      }
      if (_selectedPriority != null && task.priority != _selectedPriority) {
        return false;
      }
      return true;
    }).toList();
  }

  // --- İSTATİSTİK HESAPLAMALARI ---

  int get weeklyCompletedCount {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return _tasks.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      return t.completedAt!.isAfter(sevenDaysAgo);
    }).length;
  }

  int get monthlyCompletedCount {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (!t.isCompleted || t.completedAt == null) return false;
      return t.completedAt!.year == now.year && t.completedAt!.month == now.month;
    }).length;
  }

  int get totalCompletedCount {
    return _tasks.where((t) => t.isCompleted).length;
  }

  int get overallSuccessRate {
    if (_tasks.isEmpty) return 100;
    final completed = totalCompletedCount;
    return ((completed / _tasks.length) * 100).round();
  }

  String get mostProductiveDayName {
    final dayCounts = <int, int>{};
    for (final task in _tasks) {
      if (task.isCompleted && task.completedAt != null) {
        final day = task.completedAt!.weekday;
        dayCounts[day] = (dayCounts[day] ?? 0) + 1;
      }
    }
    if (dayCounts.isEmpty) return 'Henüz veri yok';
    final bestDay = dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    const dayNames = {
      1: 'Pazartesi',
      2: 'Salı',
      3: 'Çarşamba',
      4: 'Perşembe',
      5: 'Cuma',
      6: 'Cumartesi',
      7: 'Pazar',
    };
    return dayNames[bestDay] ?? 'Pazartesi';
  }

  // --- GÖREV İŞLEMLERİ (CRUD) ---

  Future<void> addTask(TaskItem task) async {
    _tasks.insert(0, task);
    await _persist();
    notifyListeners();
  }

  Future<TaskItem> quickAddTask(String input) async {
    final parsed = SmartTaskParser.parse(input);
    final task = TaskItem(
      id: _uuid.v4(),
      title: parsed.title,
      dueDate: parsed.dueDate ?? DateTime.now(),
      priority: parsed.priority,
      category: 'Kişisel',
      projectId: 'personal',
    );
    await addTask(task);
    return task;
  }

  Future<void> updateTask(TaskItem updatedTask) async {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> toggleTaskCompletion(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final current = _tasks[index];
      final newStatus = !current.isCompleted;
      _tasks[index] = current.copyWith(
        isCompleted: newStatus,
        completedAt: newStatus ? DateTime.now() : null,
      );

      if (newStatus) {
        _checkDailyStreak();
      }

      await _persist();
      notifyListeners();
    }
  }

  Future<void> moveAllOverdueToToday() async {
    final now = DateTime.now();
    bool changed = false;
    for (int i = 0; i < _tasks.length; i++) {
      final t = _tasks[i];
      if (!t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(DateTime(now.year, now.month, now.day))) {
        _tasks[i] = t.copyWith(dueDate: DateTime(now.year, now.month, now.day, 12, 0));
        changed = true;
      }
    }
    if (changed) {
      await _persist();
      notifyListeners();
    }
  }

  Future<void> toggleTopPriority(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final current = _tasks[index];
      final newStatus = !current.isTopPriority;
      if (newStatus && topThreeTasks.length >= 3) {
        return;
      }
      _tasks[index] = current.copyWith(isTopPriority: newStatus);
      await _persist();
      notifyListeners();
    }
  }

  // --- FİLTRELEME & ARAMA ---

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setProjectFilter(String? projectId) {
    _selectedProjectId = projectId;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _selectedProjectId = null;
    _selectedPriority = null;
    notifyListeners();
  }

  // --- HEDEF & SERİ YÖNETİMİ ---

  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal;
    await StorageService.saveDailyGoal(goal);
    notifyListeners();
  }

  void _checkDailyStreak() async {
    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final lastDateStr = await StorageService.loadLastActiveDate();

    if (lastDateStr == null) {
      if (todayCompletedCount >= _dailyGoal) {
        _streakCount = 1;
        await StorageService.saveStreakCount(1);
        await StorageService.saveLastActiveDate(todayStr);
      }
    } else if (lastDateStr != todayStr) {
      final lastDate = DateTime.parse(lastDateStr);
      final difference = DateTime(now.year, now.month, now.day)
          .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
          .inDays;

      if (difference == 1) {
        if (todayCompletedCount >= _dailyGoal) {
          _streakCount += 1;
          await StorageService.saveStreakCount(_streakCount);
          await StorageService.saveLastActiveDate(todayStr);
        }
      } else if (difference > 1) {
        if (todayCompletedCount >= _dailyGoal) {
          _streakCount = 1;
          await StorageService.saveStreakCount(1);
          await StorageService.saveLastActiveDate(todayStr);
        } else {
          _streakCount = 0;
          await StorageService.saveStreakCount(0);
        }
      }
    } else {
      if (todayCompletedCount >= _dailyGoal && _streakCount == 0) {
        _streakCount = 1;
        await StorageService.saveStreakCount(1);
      }
    }
  }

  // --- KATEGORİ İŞLEMLERİ (Geriye Dönük Uyumluluk) ---

  Future<void> addCategory(String name, int iconCode, int colorValue) async {
    final category = TaskCategory(
      id: _uuid.v4(),
      name: name,
      iconCode: iconCode,
      colorValue: colorValue,
    );
    _categories.add(category);
    await StorageService.saveCategories(_categories);
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    await StorageService.saveCategories(_categories);
    notifyListeners();
  }

  // --- YEDEK ALMA & GERİ YÜKLEME ---

  Future<String> exportBackup() async {
    return await StorageService.exportBackupJson();
  }

  Future<bool> importBackup(String jsonStr) async {
    final success = await StorageService.importBackupJson(jsonStr);
    if (success) {
      await _init();
    }
    return success;
  }

  Future<void> resetAll() async {
    await StorageService.clearAllData();
    _tasks.clear();
    _projects = ProjectModel.defaultProjects();
    _categories = TaskCategory.defaultCategories();
    _dailyGoal = 5;
    _streakCount = 0;
    notifyListeners();
  }

  Future<void> _persist() async {
    await StorageService.saveTasks(_tasks);
  }
}
