import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final todayCompleted = taskProvider.todayCompletedCount;
    final weeklyCompleted = taskProvider.weeklyCompletedCount;
    final monthlyCompleted = taskProvider.monthlyCompletedCount;
    final totalCompleted = taskProvider.totalCompletedCount;
    final streak = taskProvider.streakCount;
    final dailyGoal = taskProvider.dailyGoal;
    final successRate = taskProvider.overallSuccessRate;
    final bestDay = taskProvider.mostProductiveDayName;

    // Görev Tamamlama Puanı (Her tamamlanan görev = 15 puan, seriler ek bonus)
    final totalPoints = (totalCompleted * 15) + (streak * 25);

    return Scaffold(
      appBar: AppBar(
        title: const Text('İstatistik & Motivasyon'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Ana Puan & Üretkenlik Kartı
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Üretkenlik Puanı',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalPoints',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            '$streak Günlük Seri',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: Colors.amberAccent, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          streak > 0
                              ? 'Muazzam bir istikrar! $streak gündür hedeflerine sadıksın.'
                              : 'Her yeni gün yeni bir başlangıçtır. Küçük bir adımla başla!',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. 4'lü Özet İstatistik Izgarası
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Bugün',
                  value: '$todayCompleted / $dailyGoal',
                  subtitle: 'Günlük Hedef',
                  icon: Icons.today_rounded,
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'Bu Hafta',
                  value: '$weeklyCompleted',
                  subtitle: 'Tamamlanan',
                  icon: Icons.date_range_rounded,
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  title: 'Bu Ay',
                  value: '$monthlyCompleted',
                  subtitle: 'Tamamlanan',
                  icon: Icons.calendar_month_rounded,
                  color: Colors.purple,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  title: 'Başarı Oranı',
                  value: '%$successRate',
                  subtitle: 'Genel Oran',
                  icon: Icons.pie_chart_rounded,
                  color: Colors.orange,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. En Üretken Gün Kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Colors.amber, size: 26),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'En Üretken Günün',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bestDay,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Başarı Rozetleri (Achievements)
          const Text(
            'Başarı Rozetleri',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildBadgeCard(
            title: 'İlk Adım',
            desc: 'İlk görevini başarıyla tamamla',
            icon: '🎯',
            isUnlocked: totalCompleted >= 1,
            isDark: isDark,
          ),
          _buildBadgeCard(
            title: 'Seri Ateşi',
            desc: '3 gün üst üste günlük hedefini tamamla',
            icon: '🔥',
            isUnlocked: streak >= 3,
            isDark: isDark,
          ),
          _buildBadgeCard(
            title: 'Üretkenlik Ustası',
            desc: 'Toplamda en az 10 görevi bitir',
            icon: '⚡',
            isUnlocked: totalCompleted >= 10,
            isDark: isDark,
          ),
          _buildBadgeCard(
            title: 'Görev Şampiyonu',
            desc: 'Toplamda 25 görevi tamamla',
            icon: '🏆',
            isUnlocked: totalCompleted >= 25,
            isDark: isDark,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard({
    required String title,
    required String desc,
    required String icon,
    required bool isUnlocked,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnlocked
              ? Colors.amber.withOpacity(0.5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.amber.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              icon,
              style: TextStyle(
                fontSize: 22,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isUnlocked)
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
