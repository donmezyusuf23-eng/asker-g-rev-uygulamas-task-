import 'package:flutter/material.dart';

class TaskCategory {
  final String id;
  final String name;
  final int iconCode;
  final int colorValue;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
  });

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCode': iconCode,
      'colorValue': colorValue,
    };
  }

  factory TaskCategory.fromMap(Map<String, dynamic> map) {
    return TaskCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      iconCode: map['iconCode'] ?? Icons.label_outline.codePoint,
      colorValue: map['colorValue'] ?? Colors.blue.value,
    );
  }

  // Hazır kategoriler kaldırıldı - kullanıcı isterse kendisi ekler
  static List<TaskCategory> defaultCategories() {
    return [];
  }
}
