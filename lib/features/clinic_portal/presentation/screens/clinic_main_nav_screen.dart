import 'package:aesthetic_way/core/widgets/lazy_tab_stack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/app_snackbar.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_dashboard_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_leads_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_offers_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_profile_screen.dart';

/// Clinic Partner Navigation Shell with Floating Luxury Pill Navigation Bar
/// Visual Tab Order (LTR): [ Dashboard | Leads | Offers | Profile ]
class ClinicMainNavScreen extends StatefulWidget {
  final int initialIndex;

  const ClinicMainNavScreen({super.key, this.initialIndex = 0});

  @override
  State<ClinicMainNavScreen> createState() => _ClinicMainNavScreenState();
}

class _ClinicMainNavScreenState extends State<ClinicMainNavScreen> {
  late int _currentIndex;
  final GlobalKey<ClinicProfileScreenState> _profileKey =
      GlobalKey<ClinicProfileScreenState>();
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToProfileSection(String section) {
    _onTabSelected(3);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _profileKey.currentState?.scrollToSection(section);
    });
  }

  void _handleBackPress(BuildContext context, LocaleService loc) {
    if (_currentIndex != 0) {
      _onTabSelected(0);
      return;
    }
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      showAppSnackBar(
        context,
        loc.isArabic
            ? 'اضغط مرة أخرى للخروج من التطبيق'
            : 'Press back again to exit',
        type: AppSnackBarType.info,
      );
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final clinicService = ClinicPortalService();
    final isDark = AppColors.isDark(context);

    final screens = <WidgetBuilder>[
      (context) => ClinicDashboardScreen(
        onNavigateToLeads: () => _onTabSelected(1),
        onNavigateToOffers: () => _onTabSelected(2),
        onNavigateToProfile: () => _onTabSelected(3),
        onNavigateToSection: _navigateToProfileSection,
      ),
      (context) => const ClinicLeadsScreen(),
      (context) => const ClinicOffersScreen(),
      (context) => ClinicProfileScreen(key: _profileKey),
    ];

    return ListenableBuilder(
      listenable: Listenable.merge([loc, clinicService.navigationBadge]),
      builder: (context, _) {
        final newLeadsCount = clinicService.newLeadsCount;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBackPress(context, loc);
          },
          child: Scaffold(
            backgroundColor: AppColors.bg(context),
            body: LazyTabStack(index: _currentIndex, builders: screens),
            bottomNavigationBar: SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
                // Enforce strictly visual Left-to-Right: [ Home | Leads | Offers | Profile ]
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ClinicFloatingNavItem(
                        index: 0,
                        selectedIndex: _currentIndex,
                        icon: Icons.dashboard_outlined,
                        activeIcon: Icons.dashboard_rounded,
                        label: loc.tr('clinic_nav_dashboard'),
                        onTap: () => _onTabSelected(0),
                      ),
                      _ClinicFloatingNavItem(
                        index: 1,
                        selectedIndex: _currentIndex,
                        icon: Icons.mark_email_unread_outlined,
                        activeIcon: Icons.mark_email_read_rounded,
                        label: loc.tr('clinic_nav_leads'),
                        badgeCount: newLeadsCount,
                        onTap: () => _onTabSelected(1),
                      ),
                      _ClinicFloatingNavItem(
                        index: 2,
                        selectedIndex: _currentIndex,
                        icon: Icons.local_offer_outlined,
                        activeIcon: Icons.local_offer_rounded,
                        label: loc.tr('clinic_nav_offers'),
                        onTap: () => _onTabSelected(2),
                      ),
                      _ClinicFloatingNavItem(
                        index: 3,
                        selectedIndex: _currentIndex,
                        icon: Icons.storefront_outlined,
                        activeIcon: Icons.storefront_rounded,
                        label: loc.tr('clinic_nav_profile'),
                        onTap: () => _onTabSelected(3),
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

class _ClinicFloatingNavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  const _ClinicFloatingNavItem({
    required this.index,
    required this.selectedIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == selectedIndex;
    final isDark = AppColors.isDark(context);

    Widget iconWidget = Icon(
      isSelected ? activeIcon : icon,
      size: 20,
      color: isSelected
          ? AppColors.accentChampagne
          : (isDark ? AppColors.silverSecondary : AppColors.lightTextSecondary),
    );

    if (badgeCount > 0) {
      iconWidget = Badge(
        label: Text(
          '$badgeCount',
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.accentChampagne,
        textColor: AppColors.backgroundDeep,
        child: iconWidget,
      );
    }

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
                ? AppColors.accentChampagne.withValues(
                    alpha: isDark ? 0.15 : 0.2,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            border: isSelected
                ? Border.all(
                    color: AppColors.accentChampagne.withValues(
                      alpha: isDark ? 0.45 : 0.65,
                    ),
                    width: 0.85,
                  )
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accentChampagne.withValues(
                        alpha: isDark ? 0.12 : 0.2,
                      ),
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
                child: iconWidget,
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.goldText(context)
                      : (isDark
                            ? AppColors.silverSecondary
                            : AppColors.lightTextSecondary),
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
