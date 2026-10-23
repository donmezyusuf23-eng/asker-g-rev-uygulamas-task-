import 'package:flutter/material.dart';

class ProjectModel {
  final String id;
  String name;
  int iconCode;
  int colorValue;
  DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      iconCode: map['iconCode'] ?? Icons.folder_rounded.codePoint,
      colorValue: map['colorValue'] ?? Colors.blue.value,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }

  static List<ProjectModel> defaultProjects() {
    return [
      ProjectModel(
        id: 'personal',
        name: 'Kişisel',
        iconCode: Icons.person_rounded.codePoint,
        colorValue: 0xFF2563EB, // Blue
      ),
      ProjectModel(
        id: 'work',
        name: 'İş & Kariyer',
        iconCode: Icons.work_rounded.codePoint,
        colorValue: 0xFFF59E0B, // Amber
      ),
      ProjectModel(
        id: 'study',
        name: 'Sınav & Eğitim',
        iconCode: Icons.school_rounded.codePoint,
        colorValue: 0xFF8B5CF6, // Purple
      ),
    ];
  }
}
