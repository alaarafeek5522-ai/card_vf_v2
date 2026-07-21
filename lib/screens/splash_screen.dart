import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/vodafone_service.dart';
import '../services/license_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'license_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  String _status = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    Future.delayed(const Duration(milliseconds: 1500), _startChecks);
  }

  bool _isVersionLower(String current, String minimum) {
    final c = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final m = minimum.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < m.length; i++) {
      final cv = i < c.length ? c[i] : 0;
      if (cv < m[i]) return true;
      if (cv > m[i]) return false;
    }
    return false;
  }

  Future<void> _startChecks() async {
    setState(() => _status = 'جاري التحقق...');
    final config = await VodafoneService.fetchRemoteConfig();

    if (config['stopped'] == true) {
      _showDialog(
        icon: Icons.block_rounded,
        iconColor: AppTheme.error,
        title: 'التطبيق متوقف',
        message: config['stopped_message'] ?? 'التطبيق متوقف مؤقتاً',
        actions: [_DialogBtn(label: 'خروج', color: AppTheme.error, onTap: () => SystemNavigator.pop())],
      );
      return;
    }

    final minVersion = config['min_version']?.toString() ?? '1.0';
    final info = await PackageInfo.fromPlatform();
    if (_isVersionLower(info.version, minVersion)) {
      _showDialog(
        icon: Icons.system_update_rounded,
        iconColor: AppTheme.gold,
        title: 'تحديث جديد',
        message: config['update_message'] ?? 'يوجد تحديث جديد',
        actions: [
          _DialogBtn(
            label: '⬇️ تحديث الآن',
            color: AppTheme.gold,
            onTap: () async {
              final url = config['update_url'] ?? '';
              if (url.isNotEmpty) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
          ),
        ],
      );
      return;
    }

    setState(() => _status = 'جاري التحقق من الترخيص...');
    final licenseResult = await LicenseService.validateSavedKey();
    if (!mounted) return;

    if (licenseResult.success) {
      setState(() => _status = 'جاهز ✓');
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, a, __) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ));
      }
    } else if (licenseResult.isConnectionError) {
      _showDialog(
        icon: Icons.wifi_off_rounded,
        iconColor: AppTheme.warning,
        title: 'خطأ في الاتصال',
        message: 'تعذر الاتصال بالسيرفر\nتأكد من اتصالك بالإنترنت',
        actions: [
          _DialogBtn(label: 'إعادة المحاولة', color: AppTheme.warning, onTap: () { Navigator.pop(context); _startChecks(); }),
          _DialogBtn(label: 'خروج', color: AppTheme.textMuted, onTap: () => SystemNavigator.pop()),
        ],
      );
    } else {
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        pageBuilder: (_, a, __) => const LicenseScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ));
    }
  }

  void _showDialog({required IconData icon, required Color iconColor, required String title, required String message, required List<Widget> actions}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: iconColor.withOpacity(0.1), border: Border.all(color: iconColor.withOpacity(0.3), width: 2)),
                  child: Icon(icon, color: iconColor, size: 44),
                ),
                const SizedBox(height: 20),
                Text(title, style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(message, style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { _shimmerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          Positioned(top: -100, right: -80,
            child: Container(width: 350, height: 350,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.redVF.withOpacity(0.08),
                boxShadow: [BoxShadow(color: AppTheme.redVF.withOpacity(0.1), blurRadius: 100, spreadRadius: 50)],
              ))),
          Positioned(bottom: -80, left: -80,
            child: Container(width: 280, height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.purple.withOpacity(0.05),
                boxShadow: [BoxShadow(color: AppTheme.purple.withOpacity(0.08), blurRadius: 80, spreadRadius: 40)],
              ))),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.bgCard,
                    boxShadow: [
                      BoxShadow(color: AppTheme.redVF.withOpacity(0.3), blurRadius: 50, spreadRadius: 5),
                      BoxShadow(color: AppTheme.redVF.withOpacity(0.15), blurRadius: 100, spreadRadius: 20),
                      BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
                    ],
                    border: Border.all(color: AppTheme.redVF.withOpacity(0.2), width: 2),
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Image.asset('assets/images/app_icon.png',
                    errorBuilder: (_, __, ___) => const Icon(Icons.signal_cellular_alt, color: AppTheme.redVF, size: 70)),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 2000.ms),

                const SizedBox(height: 48),

                AnimatedBuilder(
                  animation: _shimmerCtrl,
                  builder: (_, __) => ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: const [AppTheme.redVF, AppTheme.redGlow, AppTheme.gold, AppTheme.redGlow, AppTheme.redVF],
                      stops: [
                        0.0,
                        (_shimmerCtrl.value - 0.15).clamp(0.0, 1.0),
                        _shimmerCtrl.value.clamp(0.0, 1.0),
                        (_shimmerCtrl.value + 0.15).clamp(0.0, 1.0),
                        1.0,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: Text('Card VF V2',
                      style: GoogleFonts.cairo(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.redVF)),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),

                const SizedBox(height: 8),

                Text('PREMIUM EDITION',
                  style: GoogleFonts.cairo(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted, letterSpacing: 6),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 6),

                Text('Team Tamer',
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.redVF, letterSpacing: 3),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 80),

                if (_status.isNotEmpty) ...[
                  Text(_status, style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 13)).animate().fadeIn(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        backgroundColor: AppTheme.bgElevated,
                        valueColor: const AlwaysStoppedAnimation(AppTheme.redVF),
                        minHeight: 3,
                      ),
                    ),
                  ).animate().fadeIn(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _DialogBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 8,
            shadowColor: color.withOpacity(0.3),
          ),
          onPressed: onTap,
          child: Text(label, style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }
}
