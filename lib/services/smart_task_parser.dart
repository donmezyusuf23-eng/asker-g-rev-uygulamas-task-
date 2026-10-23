import '../models/task_model.dart';

class ParsedTaskResult {
  final String title;
  final DateTime? dueDate;
  final TaskPriority priority;

  ParsedTaskResult({
    required this.title,
    this.dueDate,
    this.priority = TaskPriority.medium,
  });
}

class SmartTaskParser {
  static ParsedTaskResult parse(String input) {
    if (input.trim().isEmpty) {
      return ParsedTaskResult(title: '');
    }

    String text = input.trim();
    final lower = text.toLowerCase();
    final now = DateTime.now();

    DateTime? targetDate;
    int? targetHour;
    int? targetMinute;
    TaskPriority priority = TaskPriority.medium;

    // 1. Öncelik tespiti
    if (lower.contains('!acil') ||
        lower.contains('!yüksek') ||
        lower.contains('acil') ||
        lower.contains('önemli')) {
      priority = TaskPriority.high;
      text = text
          .replaceAll(RegExp(r'!acil|!yüksek|acil|önemli', caseSensitive: false), '')
          .trim();
    } else if (lower.contains('!düşük')) {
      priority = TaskPriority.low;
      text = text.replaceAll(RegExp(r'!düşük', caseSensitive: false), '').trim();
    }

    // 2. Gün tespiti
    if (lower.contains('öbür gün') || lower.contains('ertesi gün')) {
      targetDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 2));
      text = text
          .replaceAll(RegExp(r'öbür gün|ertesi gün', caseSensitive: false), '')
          .trim();
    } else if (lower.contains('yarın')) {
      targetDate = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
      text = text.replaceAll(RegExp(r'yarın', caseSensitive: false), '').trim();
    } else if (lower.contains('bugün')) {
      targetDate = DateTime(now.year, now.month, now.day);
      text = text.replaceAll(RegExp(r'bugün', caseSensitive: false), '').trim();
    } else {
      // Haftanın günleri kontrolü
      final daysOfWeek = {
        'pazartesi': DateTime.monday,
        'salı': DateTime.tuesday,
        'çarşamba': DateTime.wednesday,
        'perşembe': DateTime.thursday,
        'cuma': DateTime.friday,
        'cumartesi': DateTime.saturday,
        'pazar': DateTime.sunday,
      };

      for (final entry in daysOfWeek.entries) {
        if (lower.contains(entry.key)) {
          int diff = (entry.value - now.weekday) % 7;
          if (diff <= 0) diff += 7;
          targetDate = DateTime(now.year, now.month, now.day).add(Duration(days: diff));
          text = text.replaceAll(RegExp(entry.key, caseSensitive: false), '').trim();
          break;
        }
      }
    }

    // 3. Saat tespiti: "saat 14:00'te", "14.30'da", "saat 14", "15:00"
    final timeRegex = RegExp(
      r'(?:saat\s*)?(\d{1,2})[:.](\d{2})(?:\s*(?:te|ta|de|da|tarafı|gibi))?',
      caseSensitive: false,
    );
    final match = timeRegex.firstMatch(text);

    if (match != null) {
      final hour = int.tryParse(match.group(1) ?? '');
      final minute = int.tryParse(match.group(2) ?? '');
      if (hour != null && hour >= 0 && hour <= 23 && minute != null && minute >= 0 && minute <= 59) {
        targetHour = hour;
        targetMinute = minute;
        text = text.replaceRange(match.start, match.end, '').trim();
      }
    } else {
      // Sadece tek saat: "saat 14'te", "saat 9"
      final simpleHourRegex = RegExp(
        r'saat\s*(\d{1,2})(?:\s*(?:te|ta|de|da|gibi))?',
        caseSensitive: false,
      );
      final simpleMatch = simpleHourRegex.firstMatch(text);
      if (simpleMatch != null) {
        final hour = int.tryParse(simpleMatch.group(1) ?? '');
        if (hour != null && hour >= 0 && hour <= 23) {
          targetHour = hour;
          targetMinute = 0;
          text = text.replaceRange(simpleMatch.start, simpleMatch.end, '').trim();
        }
      }
    }

    // Ek bağlaç ve temizlik: " - ", "'te", "'de", "'ta", "'da" artıkları
    text = text
        .replaceAll(RegExp(r"^[\s,.\-':]+|[\s,.\-':]+$"), '')
        .replaceAll(RegExp(r"\s+"), ' ')
        .trim();

    // Tarih ve saati birleştir
    DateTime? finalDueDate;
    if (targetDate != null) {
      finalDueDate = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        targetHour ?? 12,
        targetMinute ?? 0,
      );
    } else if (targetHour != null) {
      // Gün belirtilmemişse ama saat verilmişse bugünün o saati (geçtiyse yarına)
      final candidate = DateTime(now.year, now.month, now.day, targetHour, targetMinute ?? 0);
      finalDueDate = candidate.isBefore(now)
          ? candidate.add(const Duration(days: 1))
          : candidate;
    }

    return ParsedTaskResult(
      title: text.isEmpty ? input.trim() : text,
      dueDate: finalDueDate,
      priority: priority,
    );
  }
}
