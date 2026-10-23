import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/category_model.dart';
import '../models/project_model.dart';

class StorageService {
  static const String _tasksKey = 'asker_tasks_v1';
  static const String _categoriesKey = 'asker_categories_v1';
  static const String _projectsKey = 'asker_projects_v1';
  static const String _dailyGoalKey = 'asker_daily_goal_v1';
  static const String _streakCountKey = 'asker_streak_count_v1';
  static const String _lastActiveDateKey = 'asker_last_active_date_v1';
  static const String _themeModeKey = 'asker_theme_mode_v1';

  // 1. Görevleri Yükle & Kaydet
  static Future<List<TaskItem>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_tasksKey);
    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((item) => TaskItem.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> saveTasks(List<TaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(tasks.map((t) => t.toMap()).toList());
    return await prefs.setString(_tasksKey, jsonString);
  }

  // 2. Projeleri Yükle & Kaydet
  static Future<List<ProjectModel>> loadProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_projectsKey);
    if (jsonString == null || jsonString.isEmpty) {
      final defaults = ProjectModel.defaultProjects();
      await saveProjects(defaults);
      return defaults;
    }
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((item) => ProjectModel.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      return ProjectModel.defaultProjects();
    }
  }

  static Future<bool> saveProjects(List<ProjectModel> projects) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(projects.map((p) => p.toMap()).toList());
    return await prefs.setString(_projectsKey, jsonString);
  }

  // 3. Kategorileri Yükle & Kaydet
  static Future<List<TaskCategory>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_categoriesKey);
    if (jsonString == null || jsonString.isEmpty) {
      final defaults = TaskCategory.defaultCategories();
      await saveCategories(defaults);
      return defaults;
    }
    try {
      final List<dynamic> decoded = json.decode(jsonString);
      return decoded.map((item) => TaskCategory.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      return TaskCategory.defaultCategories();
    }
  }

  static Future<bool> saveCategories(List<TaskCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(categories.map((c) => c.toMap()).toList());
    return await prefs.setString(_categoriesKey, jsonString);
  }

  // 4. Günlük Hedef & Seri Ayarları
  static Future<int> loadDailyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? 5;
  }

  static Future<bool> saveDailyGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setInt(_dailyGoalKey, goal);
  }

  static Future<int> loadStreakCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakCountKey) ?? 0;
  }

  static Future<bool> saveStreakCount(int streak) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setInt(_streakCountKey, streak);
  }

  static Future<String?> loadLastActiveDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastActiveDateKey);
  }

  static Future<bool> saveLastActiveDate(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_lastActiveDateKey, dateStr);
  }

  // 5. Tema Modu (0: System, 1: Light, 2: Dark)
  static Future<int> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_themeModeKey) ?? 0;
  }

  static Future<bool> saveThemeMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setInt(_themeModeKey, mode);
  }

  // 6. Yedekleme & Geri Yükleme (JSON Export / Import)
  static Future<String> exportBackupJson() async {
    final tasks = await loadTasks();
    final projects = await loadProjects();
    final categories = await loadCategories();
    final dailyGoal = await loadDailyGoal();
    final streak = await loadStreakCount();

    final backup = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'dailyGoal': dailyGoal,
      'streak': streak,
      'projects': projects.map((p) => p.toMap()).toList(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'tasks': tasks.map((t) => t.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  static Future<bool> importBackupJson(String jsonContent) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonContent);
      if (data.containsKey('tasks')) {
        final List<dynamic> rawTasks = data['tasks'];
        final tasks = rawTasks.map((t) => TaskItem.fromMap(Map<String, dynamic>.from(t))).toList();
        await saveTasks(tasks);
      }
      if (data.containsKey('projects')) {
        final List<dynamic> rawProjects = data['projects'];
        final projects = rawProjects.map((p) => ProjectModel.fromMap(Map<String, dynamic>.from(p))).toList();
        await saveProjects(projects);
      }
      if (data.containsKey('categories')) {
        final List<dynamic> rawCats = data['categories'];
        final categories = rawCats.map((c) => TaskCategory.fromMap(Map<String, dynamic>.from(c))).toList();
        await saveCategories(categories);
      }
      if (data.containsKey('dailyGoal')) {
        await saveDailyGoal(data['dailyGoal'] as int);
      }
      if (data.containsKey('streak')) {
        await saveStreakCount(data['streak'] as int);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
    await prefs.remove(_projectsKey);
    await prefs.remove(_categoriesKey);
    await prefs.remove(_dailyGoalKey);
    await prefs.remove(_streakCountKey);
    await prefs.remove(_lastActiveDateKey);
  }
}
