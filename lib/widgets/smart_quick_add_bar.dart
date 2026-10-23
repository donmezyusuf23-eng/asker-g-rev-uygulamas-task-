import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/smart_task_parser.dart';
import '../models/task_model.dart';

class SmartQuickAddBar extends StatefulWidget {
  const SmartQuickAddBar({super.key});

  @override
  State<SmartQuickAddBar> createState() => _SmartQuickAddBarState();
}

class _SmartQuickAddBarState extends State<SmartQuickAddBar> {
  final TextEditingController _controller = TextEditingController();
  ParsedTaskResult? _parsedPreview;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _controller.text;
    if (text.trim().isEmpty) {
      if (_parsedPreview != null) {
        setState(() => _parsedPreview = null);
      }
    } else {
      final parsed = SmartTaskParser.parse(text);
      if (parsed.dueDate != null || parsed.priority != TaskPriority.medium) {
        setState(() => _parsedPreview = parsed);
      } else {
        if (_parsedPreview != null) {
          setState(() => _parsedPreview = null);
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.quickAddTask(text);
    _controller.clear();
    setState(() => _parsedPreview = null);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Görev başarıyla eklendi!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Akıllı tespit önizleme çipleri
          if (_parsedPreview != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Akıllı Algılama',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_parsedPreview!.dueDate != null)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.calendar_today_rounded, size: 12),
                      label: Text(
                        DateFormat('d MMM, HH:mm', 'tr_TR').format(_parsedPreview!.dueDate!),
                        style: const TextStyle(fontSize: 11),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  if (_parsedPreview!.priority == TaskPriority.high)
                    Chip(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.red.withOpacity(0.12),
                      avatar: const Icon(Icons.priority_high_rounded, size: 12, color: Colors.red),
                      label: const Text(
                        'Yüksek Öncelik',
                        style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
          ],

          // Giriş kutusu ve Ekle butonu
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Hızlı görev ekle (Örn: "Yarın 14:00 raporu bitir !acil")',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(Icons.add_task_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _submit,
                icon: const Icon(Icons.arrow_upward_rounded),
                tooltip: 'Görevi Kaydet',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
