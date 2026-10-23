import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/task_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showAddCategoryDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    int selectedColor = 0xFF2196F3;
    int selectedIcon = Icons.label_rounded.codePoint;

    final colorOptions = [
      0xFF2196F3, // Mavi
      0xFF4CAF50, // Yeşil
      0xFFFF9800, // Turuncu
      0xFFE91E63, // Pembe
      0xFF9C27B0, // Mor
      0xFF00BCD4, // Turkuaz
      0xFFFF5722, // Kırmızı
      0xFF607D8B, // Gri
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Kategori Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Kategori Adı',
                  hintText: 'Örn: Finans, Hobiler',
                ),
              ),
              const SizedBox(height: 16),
              const Text('Kategori Rengi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: colorOptions.map((c) {
                  final isSelected = selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => selectedColor = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(color: Color(c).withOpacity(0.5), blurRadius: 6, spreadRadius: 1),
                        ],
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
                final text = titleCtrl.text.trim();
                if (text.isNotEmpty) {
                  Provider.of<TaskProvider>(context, listen: false)
                      .addCategory(text, selectedIcon, selectedColor);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupDialog(BuildContext context) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final backupJson = await taskProvider.exportBackup();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.backup_rounded, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Veri Yedekleme'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tüm görevleriniz, kategorileriniz ve istatistikleriniz JSON formatında hazırlandı. Bu metni kopyalayıp güvenli bir yere kaydedebilirsiniz:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  backupJson,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Panoya Kopyala'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: backupJson));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yedek panoya kopyalandı!')),
              );
            },
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _showRestoreDialog(BuildContext context) {
    final jsonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore_rounded, color: Colors.green),
            SizedBox(width: 8),
            Text('Yedeği Geri Yükle'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daha önce kopyaladığınız yedek JSON metnini buraya yapıştırın:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: jsonCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '{\n  "version": 1,\n  "tasks": [...]\n}',
                hintStyle: TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final text = jsonCtrl.text.trim();
              if (text.isNotEmpty) {
                final success = await Provider.of<TaskProvider>(context, listen: false).importBackup(text);
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Yedek başarıyla geri yüklendi!' : 'Geçersiz yedek formatı!'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Geri Yükle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Görünüm & Tema
          const _SettingsSectionHeader(title: 'GÖRÜNÜM'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_rounded, color: Colors.blueAccent),
                  title: const Text('Tema'),
                  subtitle: Text(
                    themeProvider.themeMode == ThemeMode.dark
                        ? 'Koyu Tema'
                        : themeProvider.themeMode == ThemeMode.light
                            ? 'Açık Tema'
                            : 'Sistem Teması',
                  ),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 16)),
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.settings_suggest_rounded, size: 16)),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 16)),
                    ],
                    selected: {themeProvider.themeMode},
                    onSelectionChanged: (set) => themeProvider.setThemeMode(set.first),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Üretkenlik & Hedefler
          const _SettingsSectionHeader(title: 'HEDEFLER'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.flag_rounded, color: Colors.green),
                  title: const Text('Günlük Görev Hedefi'),
                  subtitle: Text('Günde en az ${taskProvider.dailyGoal} görev tamamlama hedefi'),
                  trailing: DropdownButton<int>(
                    value: taskProvider.dailyGoal,
                    underline: const SizedBox(),
                    items: [1, 2, 3, 5, 7, 10].map((num) {
                      return DropdownMenuItem<int>(
                        value: num,
                        child: Text('$num Görev'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) taskProvider.setDailyGoal(val);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Kategoriler (İsteğe Bağlı)
          const _SettingsSectionHeader(title: 'ÖZEL KATEGORİLER'),
          Card(
            child: Column(
              children: [
                if (taskProvider.categories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Henüz özel kategori eklenmedi.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                else
                  ...taskProvider.categories.map((cat) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cat.color.withOpacity(0.15),
                        child: Icon(cat.icon, color: cat.color, size: 20),
                      ),
                      title: Text(cat.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                        onPressed: () => taskProvider.deleteCategory(cat.id),
                      ),
                    );
                  }),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline_rounded, color: Colors.blue),
                  title: const Text('Yeni Kategori Ekle', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  onTap: () => _showAddCategoryDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Veri & Güvenlik
          const _SettingsSectionHeader(title: 'VERİ VE GÜVENLİK (OFFLINE-FIRST)'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: Colors.indigo),
                  title: const Text('Yedek Al (JSON Dışa Aktar)'),
                  subtitle: const Text('Görevlerinizi metin dosyası olarak yedekleyin'),
                  onTap: () => _showBackupDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.upload_rounded, color: Colors.teal),
                  title: const Text('Yedeği Geri Yükle'),
                  subtitle: const Text('Önceden aldığınız yedeği içe aktarın'),
                  onTap: () => _showRestoreDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security_rounded, color: Colors.blueGrey),
                  title: const Text('Veri Gizliliği'),
                  subtitle: const Text('Verileriniz %100 yerel olarak cihazınızda saklanır.'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                  title: const Text('Tüm Verileri Sıfırla', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Tüm Veriler Silinsin mi?'),
                        content: const Text('Bu işlem geri alınamaz. Tüm görevleriniz ve ayarlarınız silinecektir.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Vazgeç'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Evet, Hepsini Sil'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      taskProvider.resetAll();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tüm veriler sıfırlandı.')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Uygulama Bilgisi
          const _SettingsSectionHeader(title: 'HAKKINDA'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Asker'),
                  subtitle: const Text('Sürüm 1.0.0 (Play Store Sürümü)'),
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user_rounded),
                  title: const Text('İnternetsiz & Güvenli'),
                  subtitle: const Text('Hesap gerektirmez, çevrimdışı çalışır'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final String title;

  const _SettingsSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
