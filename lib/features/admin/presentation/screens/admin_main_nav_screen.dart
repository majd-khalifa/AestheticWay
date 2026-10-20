import 'dart:async';
import '../../../../core/auth/guest_auth_guard.dart';
import '../../services/admin_portal_service.dart';
import '../widgets/admin_components.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'package:aesthetic_way/core/widgets/lazy_tab_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_clinics_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_leads_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_offers_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_analytics_screen.dart';
import 'package:aesthetic_way/features/admin/presentation/screens/admin_settings_screen.dart';

/// Super Admin Main Navigation Shell with Floating Luxury Pill Navigation Bar
/// Visual Tab Order (LTR): [ Dashboard | Clinics | Leads | Offers | Analytics ]
class AdminMainNavScreen extends StatefulWidget {
  final int initialIndex;

  const AdminMainNavScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminMainNavScreen> createState() => _AdminMainNavScreenState();
}

class _AdminMainNavScreenState extends State<AdminMainNavScreen> {
  late int _currentIndex;
  Timer? _backReset;
  bool _exitArmed = false;
  bool _redirecting = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    AuthState().addListener(_sessionChanged);
  }

  @override
  void dispose() {
    _backReset?.cancel();
    AuthState().removeListener(_sessionChanged);
    super.dispose();
  }

  void _sessionChanged() {
    if (_redirecting || AdminPortalService().canManage) return;
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    });
  }

  void _onTabSelected(int index) {
    if (index == 0) AdminPortalService().loadOverview();
    if (_currentIndex != index) {
      _exitArmed = false;
      _backReset?.cancel();
      HapticFeedback.selectionClick();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _handleBackPress(BuildContext context, LocaleService loc) {
    if (_currentIndex != 0) {
      _onTabSelected(0);
      return;
    }
    if (!_exitArmed) {
      _exitArmed = true;
      _backReset?.cancel();
      _backReset = Timer(const Duration(seconds: 2), () => _exitArmed = false);
      showAppSnackBar(
        context,
        loc.isArabic
            ? 'اضغط مرة أخرى للخروج من التطبيق'
            : 'Press back again to exit',
        type: AppSnackBarType.info,
      );
      return;
    }
    _backReset?.cancel();
    _exitArmed = false;
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final screens = <WidgetBuilder>[
      (context) => AdminDashboardScreen(
        onNavigateToClinics: () => _onTabSelected(1),
        onNavigateToLeads: () => _onTabSelected(2),
        onNavigateToAnalytics: () => _onTabSelected(4),
      ),
      (context) => const AdminClinicsScreen(),
      (context) => const AdminLeadsScreen(),
      (context) => const AdminOffersScreen(),
      (context) => const AdminAnalyticsScreen(),
    ];

    return ListenableBuilder(
      listenable: Listenable.merge([loc, AuthState()]),
      builder: (context, _) {
        if (!AdminPortalService().canManage) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AdminNotice(
                        message: adminText(
                          'Super Admin access is required.',
                          'يتطلب الوصول حساب مشرف عام.',
                        ),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                              (_) => false,
                            ),
                        child: Text(adminText('Sign in', 'تسجيل الدخول')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBackPress(context, loc);
          },
          child: Scaffold(
            backgroundColor: AppColors.bg(context),
            appBar: AppBar(
              toolbarHeight:
                  (MediaQuery.textScalerOf(context).scale(15) * 2.6 + 12)
                      .clamp(kToolbarHeight, double.infinity)
                      .toDouble(),
              backgroundColor: AppColors.bg(context),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    color: AppColors.goldText(context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      loc.tr(
                        const [
                          'admin_title_dashboard',
                          'admin_title_clinics',
                          'admin_title_leads',
                          'admin_title_catalog',
                          'admin_title_analytics',
                        ][_currentIndex],
                      ),
                      style: TextStyle(
                        color: isDark
                            ? AppColors.silverPrimary
                            : AppColors.lightTextPrimary,
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.settings_outlined,
                    color: AppColors.goldText(context),
                    size: 20,
                  ),
                  tooltip: loc.tr('admin_nav_settings'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      LuxuryPageRoute(page: const AdminSettingsScreen()),
                    );
                  },
                ),
              ],
            ),
            body: LazyTabStack(index: _currentIndex, builders: screens),
            bottomNavigationBar: SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF080D1A).withValues(alpha: 0.96)
                      : Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 0.85,
                  ),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: AppColors.silverPrimary.withValues(
                              alpha: 0.04,
                            ),
                            blurRadius: 1,
                            spreadRadius: 0.5,
                            offset: const Offset(0, -0.5),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: const Color(
                              0xFF0F172A,
                            ).withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 2,
                            spreadRadius: 0.5,
                            offset: const Offset(0, -0.5),
                          ),
                        ],
                ),
                // Enforce strictly visual Left-to-Right: [ Home | Clinics | Leads | Offers | Analytics ]
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _AdminFloatingNavItem(
                        index: 0,
                        selectedIndex: _currentIndex,
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                        label: loc.tr('admin_nav_dashboard'),
                        onTap: () => _onTabSelected(0),
                      ),
                      _AdminFloatingNavItem(
                        index: 1,
                        selectedIndex: _currentIndex,
                        icon: Icons.apartment_outlined,
                        activeIcon: Icons.apartment_rounded,
                        label: loc.tr('admin_nav_clinics'),
                        onTap: () => _onTabSelected(1),
                      ),
                      _AdminFloatingNavItem(
                        index: 2,
                        selectedIndex: _currentIndex,
                        icon: Icons.mark_email_read_outlined,
                        activeIcon: Icons.mark_email_read_rounded,
                        label: loc.tr('admin_nav_leads'),
                        onTap: () => _onTabSelected(2),
                      ),
                      _AdminFloatingNavItem(
                        index: 3,
                        selectedIndex: _currentIndex,
                        icon: Icons.local_offer_outlined,
                        activeIcon: Icons.local_offer_rounded,
                        label: loc.tr('admin_nav_offers'),
                        onTap: () => _onTabSelected(3),
                      ),
                      _AdminFloatingNavItem(
                        index: 4,
                        selectedIndex: _currentIndex,
                        icon: Icons.analytics_outlined,
                        activeIcon: Icons.analytics_rounded,
                        label: loc.tr('admin_nav_analytics'),
                        onTap: () => _onTabSelected(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdminFloatingNavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _AdminFloatingNavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final isDark = AppColors.isDark(context);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.darkGold.withValues(alpha: isDark ? 0.15 : 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: isSelected
                  ? Border.all(
                      color: AppColors.darkGold.withValues(
                        alpha: isDark ? 0.45 : 0.65,
                      ),
                      width: 0.85,
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.10 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    size: 19,
                    color: isSelected
                        ? AppColors.goldText(context)
                        : (isDark
                              ? AppColors.silverSecondary
                              : AppColors.lightTextSecondary),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.goldText(context)
                        : (isDark
                              ? AppColors.silverSecondary
                              : AppColors.lightTextSecondary),
                  ),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
