import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/license_service.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class LicenseScreen extends StatefulWidget {
  const LicenseScreen({super.key});
  @override
  State<LicenseScreen> createState() => _LicenseScreenState();
}

class _LicenseScreenState extends State<LicenseScreen> {
  final _keyCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _keyVisible = true;

  Future<void> _activate() async {
    final key = _keyCtrl.text.trim().toUpperCase();
    if (key.isEmpty) { setState(() => _error = 'ادخل مفتاح التفعيل'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      final result = await LicenseService.activateKey(key);
      if (!mounted) return;
      if (result.success) {
        HapticFeedback.lightImpact();
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, a, __) => const HomeScreen(),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ));
      } else {
        HapticFeedback.vibrate();
        setState(() => _error = result.message ?? 'المفتاح غير صحيح');
      }
    } catch (e) {
      setState(() => _error = 'خطأ في الاتصال، حاول مرة أخرى');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          Positioned(top: -120, right: -80,
            child: Container(width: 320, height: 320,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.redVF.withOpacity(0.06),
                boxShadow: [BoxShadow(color: AppTheme.redVF.withOpacity(0.08), blurRadius: 100, spreadRadius: 40)],
              ))),
          Positioned(bottom: -100, left: -60,
            child: Container(width: 280, height: 280,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.purple.withOpacity(0.04),
                boxShadow: [BoxShadow(color: AppTheme.purple.withOpacity(0.06), blurRadius: 80, spreadRadius: 30)],
              ))),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.bgCard,
                      boxShadow: [
                        BoxShadow(color: AppTheme.redVF.withOpacity(0.25), blurRadius: 40, spreadRadius: 4),
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                      border: Border.all(color: AppTheme.redVF.withOpacity(0.15), width: 2),
                    ),
                    padding: const EdgeInsets.all(22),
                    child: Image.asset('assets/images/app_icon.png',
                      errorBuilder: (_, __, ___) => const Icon(Icons.vpn_key_rounded, color: AppTheme.redVF, size: 50)),
                  ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: 32),

                  Text('Card VF V2',
                    style: GoogleFonts.cairo(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                  const SizedBox(height: 6),

                  Text('PREMIUM EDITION',
                    style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textMuted, letterSpacing: 4),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 8),

                  Text('Team Tamer',
                    style: GoogleFonts.cairo(fontSize: 13, color: AppTheme.redVF, fontWeight: FontWeight.w600, letterSpacing: 2),
                  ).animate().fadeIn(delay: 180.ms),

                  const SizedBox(height: 48),

                  Container(
                    decoration: AppTheme.glowCard(),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.redVF.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.redVF.withOpacity(0.2)),
                              ),
                              child: const Icon(Icons.vpn_key_rounded, color: AppTheme.redVF, size: 22)),
                            const SizedBox(width: 12),
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('تفعيل التطبيق',
                                style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                              Text('أدخل مفتاح التفعيل الخاص بك',
                                style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.textSecondary)),
                            ]),
                          ]),

                          const SizedBox(height: 24),

                          TextField(
                            controller: _keyCtrl,
                            textAlign: TextAlign.center,
                            textCapitalization: TextCapitalization.characters,
                            obscureText: !_keyVisible,
                            style: GoogleFonts.cairo(
                              fontSize: 18, fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary, letterSpacing: 3),
                            decoration: InputDecoration(
                              hintText: 'XXXX-XXXX-XXXX',
                              hintStyle: GoogleFonts.cairo(color: AppTheme.textMuted, letterSpacing: 3),
                              filled: true,
                              fillColor: AppTheme.bgElevated,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: AppTheme.redVF, width: 2)),
                              prefixIcon: const Icon(Icons.key_rounded, color: AppTheme.redVF),
                              suffixIcon: IconButton(
                                icon: Icon(_keyVisible ? Icons.visibility_off : Icons.visibility, color: AppTheme.textMuted),
                                onPressed: () => setState(() => _keyVisible = !_keyVisible),
                              ),
                            ),
                          ),

                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_error!, style: GoogleFonts.cairo(color: AppTheme.error, fontSize: 13))),
                              ]),
                            ),
                          ],

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity, height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: EdgeInsets.zero),
                              onPressed: _loading ? null : _activate,
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: _loading
                                      ? const LinearGradient(colors: [AppTheme.textMuted, AppTheme.textMuted])
                                      : const LinearGradient(
                                          colors: [AppTheme.redVF, AppTheme.redDark],
                                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: AppTheme.redVF.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                                ),
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(width: 24, height: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                          const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                                          const SizedBox(width: 10),
                                          Text('تفعيل', style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                                        ]),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 16),

                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => launchUrl(
                      Uri.parse('https://wa.me/+201093150781'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                        const SizedBox(width: 8),
                        Text('التواصل عبر واتساب',
                          style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 12),

                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => launchUrl(
                      Uri.parse('https://t.me/X_Abo_Abbas_x'),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.bgElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.telegram, color: Color(0xFF0088CC), size: 20),
                        const SizedBox(width: 8),
                        Text('الدعم عبر تلجرام',
                          style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ).animate().fadeIn(delay: 350.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
