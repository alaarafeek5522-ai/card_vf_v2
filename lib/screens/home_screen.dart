import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

import '../models/card_model.dart';
import '../theme/app_theme.dart';
import 'charge_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<CardModel> _cards = CardModel.getAll();
  String _search = '';
  bool _isLoading = true;
  bool _isOffline = false;
  int _selectedTab = 0;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startConnectivityMonitoring();
  }

  Future<void> _startConnectivityMonitoring() async {
    await _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() => _isOffline = results.isEmpty || results.contains(ConnectivityResult.none));
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (!mounted) return;
    setState(() => _isOffline = results.isEmpty || results.contains(ConnectivityResult.none));
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _isLoading = false);
  }

  List<CardModel> get _filtered {
    if (_search.isEmpty) {
      if (_selectedTab == 1) return CardModel.getFakka();
      if (_selectedTab == 2) return CardModel.getMared();
      if (_selectedTab == 3) return CardModel.getPopular();
      return _cards;
    }
    return _cards.where((card) => card.name.contains(_search) || card.netCharge.contains(_search)).toList();
  }

  Future<void> _contactWhatsApp() async {
    final uri = Uri.parse('https://wa.me/+201093150781');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح واتساب', style: GoogleFonts.cairo())),
        );
      }
    } catch (_) {}
  }

  Future<void> _contactTelegram() async {
    final uri = Uri.parse('https://t.me/X_Abo_Abbas_x');
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح تلجرام', style: GoogleFonts.cairo())),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Card VF', style: GoogleFonts.cairo(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                        Text('V2 Premium', style: GoogleFonts.cairo(fontSize: 12, color: AppTheme.redVF, fontWeight: FontWeight.w600, letterSpacing: 2)),
                      ],
                    ),
                  ),
                  _IconButton(
                    icon: Icons.history_rounded,
                    onTap: () => Navigator.push(context, _SlideRoute(page: const HistoryScreen())),
                  ),
                  const SizedBox(width: 8),
                  _IconButton(
                    icon: Icons.bar_chart_rounded,
                    onTap: () => Navigator.push(context, _SlideRoute(page: const StatsScreen())),
                  ),
                  const SizedBox(width: 8),
                  _IconButton(
                    icon: Icons.support_agent_rounded,
                    color: const Color(0xFF25D366),
                    onTap: _contactWhatsApp,
                  ),
                  const SizedBox(width: 8),
                  _IconButton(
                    icon: Icons.telegram,
                    color: const Color(0xFF0088CC),
                    onTap: _contactTelegram,
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: TextField(
                onChanged: (value) => setState(() => _search = value),
                style: GoogleFonts.cairo(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'ابحث عن باقة...',
                  hintStyle: GoogleFonts.cairo(color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.bgCard,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.redVF, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Row(
                children: [
                  _TabChip(label: 'الكل', selected: _selectedTab == 0, onTap: () => setState(() => _selectedTab = 0)),
                  const SizedBox(width: 8),
                  _TabChip(label: 'فكة', selected: _selectedTab == 1, onTap: () => setState(() => _selectedTab = 1)),
                  const SizedBox(width: 8),
                  _TabChip(label: 'مارد', selected: _selectedTab == 2, onTap: () => setState(() => _selectedTab = 2)),
                  const SizedBox(width: 8),
                  _TabChip(label: 'الأكثر مبيعا', selected: _selectedTab == 3, onTap: () => setState(() => _selectedTab = 3)),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Container(width: 4, height: 18,
                    decoration: BoxDecoration(color: AppTheme.redVF, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('الباقات المتاحة', style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${_filtered.length} باقة', style: GoogleFonts.cairo(color: AppTheme.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ),

          if (_isLoading)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.9),
                delegate: SliverChildBuilderDelegate((context, index) => const _SkeletonCard(), childCount: 6),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.9),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _CardTile(card: _filtered[index])
                        .animate().fadeIn(delay: (index * 40).ms, duration: 300.ms).scale(begin: const Offset(0.9, 0.9));
                  },
                  childCount: _filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _IconButton({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: color ?? AppTheme.textPrimary, size: 20),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.redVF.withOpacity(0.15) : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.redVF.withOpacity(0.3) : Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Text(label,
          style: GoogleFonts.cairo(color: selected ? AppTheme.redVF : AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final CardModel card;
  const _CardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, _SlideRoute(page: ChargeScreen(card: card))),
      child: Container(
        decoration: AppTheme.glowCard(glowColor: card.isPopular ? AppTheme.gold : null),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44, height: 44,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: card.category == CardCategory.mared ? AppTheme.purple.withOpacity(0.1) : AppTheme.redVF.withOpacity(0.08),
                      border: Border.all(
                        color: card.category == CardCategory.mared ? AppTheme.purple.withOpacity(0.2) : AppTheme.redVF.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      card.category == CardCategory.mared ? Icons.gamepad : Icons.signal_cellular_alt,
                      color: card.category == CardCategory.mared ? AppTheme.purple : AppTheme.redVF,
                      size: 22,
                    ),
                  ),
                  if (card.isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                      ),
                      child: Text('🔥', style: GoogleFonts.cairo(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  if (card.isNew)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.teal.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.teal.withOpacity(0.3)),
                      ),
                      child: Text('NEW', style: GoogleFonts.cairo(fontSize: 9, color: AppTheme.teal, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.name, style: GoogleFonts.cairo(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.bolt, color: AppTheme.goldDim, size: 12),
                    const SizedBox(width: 2),
                    Expanded(child: Text(card.units, style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  Row(children: [
                    Icon(Icons.access_time, color: AppTheme.info, size: 12),
                    const SizedBox(width: 2),
                    Text(card.duration, style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 10)),
                  ]),
                ],
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.redVF, AppTheme.redDark]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: AppTheme.redVF.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Text('${card.netCharge} ج',
                  style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(_controller);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard.withOpacity(_animation.value + 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: AppTheme.bgElevated.withOpacity(0.5), borderRadius: BorderRadius.circular(12))),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: 80, height: 12, decoration: BoxDecoration(color: AppTheme.bgElevated.withOpacity(0.5), borderRadius: BorderRadius.circular(6))),
                  const SizedBox(height: 6),
                  Container(width: 50, height: 10, decoration: BoxDecoration(color: AppTheme.bgElevated.withOpacity(0.3), borderRadius: BorderRadius.circular(6))),
                ]),
                Container(width: double.infinity, height: 34, decoration: BoxDecoration(color: AppTheme.bgElevated.withOpacity(0.5), borderRadius: BorderRadius.circular(10))),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SlideRoute extends PageRouteBuilder {
  final Widget page;
  _SlideRoute({required this.page}) : super(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInOutCubic);
      final slide = Tween<Offset>(begin: const Offset(0.12, 0.0), end: Offset.zero).animate(curved);
      final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
      final scale = Tween<double>(begin: 0.985, end: 1.0).animate(curved);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: ScaleTransition(scale: scale, child: child)),
      );
    },
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 300),
  );
}
