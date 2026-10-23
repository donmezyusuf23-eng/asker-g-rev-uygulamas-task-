import 'package:flutter_test/flutter_test.dart';
import 'package:asker/models/task_model.dart';
import 'package:asker/models/project_model.dart';
import 'package:asker/services/smart_task_parser.dart';

void main() {
  group('SmartTaskParser Testleri', () {
    test('Doğal dil ifadesinden tarih, saat ve öncelik ayıklanır', () {
      final input = 'Yarın saat 14:00 proje raporunu bitir !acil';
      final result = SmartTaskParser.parse(input);

      expect(result.priority, TaskPriority.high);
      expect(result.dueDate, isNotNull);
      expect(result.dueDate!.hour, 14);
      expect(result.dueDate!.minute, 0);
      expect(result.title.contains('proje raporunu bitir'), isTrue);
    });

    test('Bugün saat tespiti', () {
      final input = 'Bugün saat 18:30 spor salonuna git';
      final result = SmartTaskParser.parse(input);

      expect(result.dueDate, isNotNull);
      expect(result.dueDate!.hour, 18);
      expect(result.dueDate!.minute, 30);
      expect(result.title.contains('spor salonuna git'), isTrue);
    });
  });

  group('TaskItem ve Project Model Testleri', () {
    test('Project ve Task serileştirme testleri', () {
      final project = ProjectModel(
        id: 'ales-123',
        name: 'ALES Sınavı',
        iconCode: 1234,
        colorValue: 0xFF8B5CF6,
      );

      final task = TaskItem(
        id: 'task-123',
        title: 'Sayısal Mantık',
        projectId: project.id,
        category: project.name,
      );

      final pMap = project.toMap();
      final pRecovered = ProjectModel.fromMap(pMap);
      expect(pRecovered.name, 'ALES Sınavı');
      expect(pRecovered.id, 'ales-123');

      final tMap = task.toMap();
      final tRecovered = TaskItem.fromMap(tMap);
      expect(tRecovered.projectId, 'ales-123');
      expect(tRecovered.category, 'ALES Sınavı');
    });
  });
}
