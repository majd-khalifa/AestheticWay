import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
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
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdminPortalService().loadAllData();
    });
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
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
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      showAppSnackBar(
        context,
        loc.isArabic ? 'اضغط مرة أخرى للخروج من التطبيق' : 'Press back again to exit',
        type: AppSnackBarType.info,
      );
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final adminService = AdminPortalService();
    final isDark = AppColors.isDark(context);

    final screens = [
      AdminDashboardScreen(
        onNavigateToClinics: () => _onTabSelected(1),
        onNavigateToLeads: () => _onTabSelected(2),
        onNavigateToAnalytics: () => _onTabSelected(4),
      ),
      const AdminClinicsScreen(),
      const AdminLeadsScreen(),
      const AdminOffersScreen(),
      const AdminAnalyticsScreen(),
    ];

    return ListenableBuilder(
      listenable: Listenable.merge([loc, adminService]),
      builder: (context, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBackPress(context, loc);
          },
          child: Scaffold(
            backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_rounded, color: AppColors.accentChampagne, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    loc.tr('admin_portal_title'),
                    style: TextStyle(
                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: AppColors.accentChampagne, size: 20),
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
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
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
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: AppColors.silverPrimary.withValues(alpha: 0.04),
                          blurRadius: 1,
                          spreadRadius: 0.5,
                          offset: const Offset(0, -0.5),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.08),
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
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentChampagne.withValues(alpha: isDark ? 0.15 : 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: isSelected
                ? Border.all(
                    color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.45 : 0.65),
                    width: 0.85,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accentChampagne.withValues(alpha: isDark ? 0.12 : 0.2),
                      blurRadius: 10,
                      spreadRadius: 0.5,
                    ),
                  ]
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
                      ? AppColors.accentChampagne
                      : (isDark ? AppColors.silverSecondary : AppColors.lightTextSecondary),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.accentChampagne
                      : (isDark ? AppColors.silverSecondary : AppColors.lightTextSecondary),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
