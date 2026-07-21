import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:confetti/confetti.dart';
import '../models/card_model.dart';
import '../services/vodafone_service.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

class ChargeScreen extends StatefulWidget {
  final CardModel card;
  const ChargeScreen({super.key, required this.card});
  @override
  State<ChargeScreen> createState() => _ChargeScreenState();
}

class _ChargeScreenState extends State<ChargeScreen>
    with SingleTickerProviderStateMixin {
  final _receiverCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  late ConfettiController _confettiCtrl;
  bool _loading = false;
  bool _pinVisible = false;
  String? _resultMsg;
  bool? _success;
  String? _lastReceiver;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _loadLastReceiver();
    _confettiCtrl = ConfettiController(duration: const Duration(seconds: 3));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _confettiCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  Future<void> _loadLastReceiver() async {
    final last = await HistoryService.getLastReceiver();
    setState(() => _lastReceiver = last);
  }

  Future<void> _pickContact() async {
    final status = await Permission.contacts.request();
    if (!status.isGranted) return;
    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;
      final full = await FlutterContacts.getContact(contact.id);
      final phone = full?.phones.firstOrNull?.number
          .replaceAll(RegExp(r'\s|-|\\+20'), '').trim();
      if (phone != null && phone.isNotEmpty) {
        setState(() => _receiverCtrl.text = phone.startsWith('0') ? phone : '0$phone');
      }
    } catch (_) {}
  }

  Future<void> _confirmAndCharge() async {
    final receiver = _receiverCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (!receiver.startsWith('01') || receiver.length != 11) {
      _showSnack('رقم الهاتف غير صحيح');
      return;
    }
    if (pin.isEmpty) { _showSnack('ادخل الرقم السري'); return; }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.redVF.withOpacity(0.1),
                    border: Border.all(color: AppTheme.redVF.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.send_rounded, color: AppTheme.redVF, size: 36)),
                const SizedBox(height: 16),
                Text('تأكيد الشحن',
                  style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(children: [
                    _ConfirmRow(icon: Icons.credit_card, label: 'الكارت', value: widget.card.name),
                    const SizedBox(height: 8),
                    _ConfirmRow(icon: Icons.attach_money, label: 'السعر', value: '${widget.card.netCharge} جنيه'),
                    const SizedBox(height: 8),
                    _ConfirmRow(icon: Icons.phone, label: 'المستلم', value: receiver),
                  ]),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.bgElevated,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('إلغاء', style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: EdgeInsets.zero),
                      onPressed: () => Navigator.pop(context, true),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.redVF, AppTheme.redDark]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: AppTheme.redVF.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text('تأكيد', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) return;
    await _charge();
  }

  Future<void> _charge() async {
    final receiver = _receiverCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    setState(() { _loading = true; _resultMsg = null; _success = null; });

    final isVF = await VodafoneService.isVodafoneNetwork();
    if (!isVF) {
      setState(() => _loading = false);
      _showNetworkDialog();
      return;
    }

    try {
      final seamless = await VodafoneService.getSeamlessData();
      final seamlessToken = seamless['token'] ?? seamless['seamlessToken'];
      final senderMsisdn = (seamless['msisdn'] ?? '').toString();
      if (seamlessToken == null || senderMsisdn.isEmpty) {
        throw Exception('تعذر جلب بيانات خط فودافون، تأكد من اتصالك بشبكة فودافون');
      }
      final accessToken = await VodafoneService.getAccessToken(seamlessToken);
      if (accessToken == null) throw Exception('فشل التحقق من الحساب، حاول مرة أخرى');

      final result = await VodafoneService.chargeCard(
        productId: widget.card.productId,
        receiver: receiver,
        pin: pin,
        senderMsisdn: senderMsisdn,
        accessToken: accessToken,
      );

      final ok = (result['success'] == true) ||
          (result['status']?.toString().toLowerCase() == 'success') ||
          (result['state']?.toString().toLowerCase() == 'completed');
      final resultMessage = (result['message'] ?? result['error']?['message'])?.toString();

      if (ok) { HapticFeedback.heavyImpact(); _confettiCtrl.play(); }
      else { HapticFeedback.vibrate(); }

      await HistoryService.addRecord(
        cardName: widget.card.name, netCharge: widget.card.netCharge,
        phone: receiver, success: ok, productId: widget.card.productId);

      setState(() {
        _success = ok;
        _resultMsg = ok ? 'تم الشحن بنجاح!' : (resultMessage ?? 'فشل الشحن');
        if (ok) _lastReceiver = receiver;
      });
    } catch (e) {
      HapticFeedback.vibrate();
      await HistoryService.addRecord(
        cardName: widget.card.name, netCharge: widget.card.netCharge,
        phone: receiver, success: false, productId: widget.card.productId);
      setState(() { _success = false; _resultMsg = e.toString().replaceAll("Exception: ", ""); });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showNetworkDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard, borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40)]),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.warning.withOpacity(0.1),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3), width: 2)),
                child: const Icon(Icons.signal_cellular_off_rounded, color: AppTheme.warning, size: 40)),
              const SizedBox(height: 20),
              Text('شبكة غير مدعومة', style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('التطبيق يعمل فقط على داتا فودافون',
                style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 14), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () => Navigator.pop(context),
                  child: Text('حسناً', style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                )),
            ]),
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.cairo()),
      backgroundColor: AppTheme.redVF,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context)),
        title: Text(widget.card.name, style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(top: -100, right: -80,
            child: Container(width: 300, height: 300,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: AppTheme.redVF.withOpacity(0.05),
                boxShadow: [BoxShadow(color: AppTheme.redVF.withOpacity(0.08), blurRadius: 100, spreadRadius: 40)],
              ))),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false, numberOfParticles: 30, gravity: 0.3,
              colors: const [AppTheme.redVF, AppTheme.gold, Colors.white, AppTheme.redGlow],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _CardDetails(card: widget.card).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                const SizedBox(height: 24),

                Container(
                  decoration: AppTheme.glowCard(),
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('رقم المستلم', style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _receiverCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 11,
                      style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 18, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: '01XXXXXXXXX',
                        hintStyle: GoogleFonts.cairo(color: AppTheme.textMuted),
                        filled: true, fillColor: AppTheme.bgElevated,
                        counterStyle: const TextStyle(color: AppTheme.textMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.redVF, width: 2)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.contacts_rounded, color: AppTheme.redVF),
                          onPressed: _pickContact),
                      ),
                    ),
                    if (_lastReceiver != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _receiverCtrl.text = _lastReceiver!),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.redVF.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.redVF.withOpacity(0.2))),
                          child: Row(children: [
                            const Icon(Icons.history_rounded, color: AppTheme.redVF, size: 16),
                            const SizedBox(width: 8),
                            Text('آخر رقم: $_lastReceiver', style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 13)),
                            const Spacer(),
                            Text('استخدام', style: GoogleFonts.cairo(color: AppTheme.redVF, fontSize: 11, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      ),
                    ],
                  ]),
                ),

                const SizedBox(height: 12),

                Container(
                  decoration: AppTheme.glowCard(),
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الرقم السري للمحفظة', style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: !_pinVisible,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 20, letterSpacing: 6),
                      decoration: InputDecoration(
                        hintText: '••••••',
                        hintStyle: GoogleFonts.cairo(color: AppTheme.textMuted),
                        filled: true, fillColor: AppTheme.bgElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppTheme.redVF, width: 2)),
                        suffixIcon: IconButton(
                          icon: Icon(_pinVisible ? Icons.visibility_off : Icons.visibility, color: AppTheme.textMuted),
                          onPressed: () => setState(() => _pinVisible = !_pinVisible)),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 28),

                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(scale: _loading ? 1.0 : _pulseAnim.value, child: child),
                  child: SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: EdgeInsets.zero),
                      onPressed: _loading ? null : _confirmAndCharge,
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: _loading
                              ? const LinearGradient(colors: [AppTheme.textMuted, AppTheme.textMuted])
                              : const LinearGradient(colors: [AppTheme.redVF, AppTheme.redDark],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppTheme.redVF.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))]),
                        child: Center(
                          child: _loading
                              ? const SizedBox(width: 26, height: 26,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text('إرسال الكارت',
                                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                                ]),
                        ),
                      ),
                    ),
                  ),
                ),

                if (_resultMsg != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _success == true ? AppTheme.success.withOpacity(0.08) : AppTheme.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _success == true ? AppTheme.success.withOpacity(0.3) : AppTheme.error.withOpacity(0.3))),
                    child: Text(_resultMsg!,
                      style: GoogleFonts.cairo(
                        color: _success == true ? AppTheme.success : AppTheme.error,
                        fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ConfirmRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppTheme.redVF, size: 16),
      const SizedBox(width: 8),
      Text('$label: ', style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 13)),
      Expanded(child: Text(value,
        style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class _CardDetails extends StatelessWidget {
  final CardModel card;
  const _CardDetails({required this.card});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glowCard(
        glowColor: card.isPopular ? AppTheme.gold : null,
      ),
      child: Row(children: [
        Container(width: 60, height: 60,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: card.category == CardCategory.mared
                ? AppTheme.purple.withOpacity(0.1)
                : AppTheme.redVF.withOpacity(0.08),
            border: Border.all(
              color: card.category == CardCategory.mared
                  ? AppTheme.purple.withOpacity(0.2)
                  : AppTheme.redVF.withOpacity(0.2),
              width: 1.5)),
          padding: const EdgeInsets.all(10),
          child: Image.asset('assets/images/app_icon.png',
            errorBuilder: (_, __, ___) => Icon(
              card.category == CardCategory.mared ? Icons.gamepad : Icons.signal_cellular_alt,
              color: card.category == CardCategory.mared ? AppTheme.purple : AppTheme.redVF, size: 28))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(card.name, style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Row(children: [const Icon(Icons.bolt, color: AppTheme.goldDim, size: 14), const SizedBox(width: 4),
            Text(card.units, style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 12))]),
          Row(children: [const Icon(Icons.access_time, color: AppTheme.info, size: 14), const SizedBox(width: 4),
            Text(card.duration, style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 12))]),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.redVF, AppTheme.redDark]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppTheme.redVF.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
          child: Text('${card.netCharge}\nجنيه',
            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center)),
      ]),
    );
  }
}
