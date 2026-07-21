import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await HistoryService.getStats();
    if (mounted) setState(() { _stats = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('الإحصائيات', style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.redVF))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _StatCard(
                    icon: Icons.receipt_long,
                    iconColor: AppTheme.info,
                    title: 'إجمالي العمليات',
                    value: '${_stats['total'] ?? 0}',
                    subtitle: 'عملية شحن',
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),

                  const SizedBox(height: 12),

                  Row(children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle,
                        iconColor: AppTheme.success,
                        title: 'ناجحة',
                        value: '${_stats['successful'] ?? 0}',
                        subtitle: 'عملية',
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: -0.1),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.cancel,
                        iconColor: AppTheme.error,
                        title: 'فاشلة',
                        value: '${_stats['failed'] ?? 0}',
                        subtitle: 'عملية',
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: -0.1),
                    ),
                  ]),

                  const SizedBox(height: 12),

                  _StatCard(
                    icon: Icons.attach_money,
                    iconColor: AppTheme.gold,
                    title: 'إجمالي المبالغ المشحونة',
                    value: '${_stats['totalAmount'] ?? '0.00'}',
                    subtitle: 'جنيه مصري',
                    isLarge: true,
                  ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: -0.1),

                  const SizedBox(height: 32),

                  if ((_stats['total'] ?? 0) > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glowCard(),
                      child: Column(
                        children: [
                          Text('نسبة النجاح', style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          _SuccessRing(
                            success: _stats['successful'] ?? 0,
                            total: _stats['total'] ?? 1,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;
  final bool isLarge;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glowCard(glowColor: iconColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.cairo(
            color: AppTheme.textPrimary,
            fontSize: isLarge ? 32 : 24,
            fontWeight: FontWeight.w900,
          )),
          Text(subtitle, style: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _SuccessRing extends StatelessWidget {
  final int success;
  final int total;
  const _SuccessRing({required this.success, required this.total});

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (success / total * 100).toStringAsFixed(1) : '0.0';
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: total > 0 ? success / total : 0,
              strokeWidth: 12,
              backgroundColor: AppTheme.bgElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.success),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$percentage%', style: GoogleFonts.cairo(
                color: AppTheme.success,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              )),
              Text('معدل النجاح', style: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
