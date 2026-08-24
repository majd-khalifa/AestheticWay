import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/home/presentation/screens/home_screen.dart';
import 'package:aesthetic_way/features/clinics/presentation/screens/clinics_list_screen.dart';
import 'package:aesthetic_way/features/appointment_lead/presentation/screens/my_requests_screen.dart';
import 'package:aesthetic_way/features/profile/presentation/screens/profile_screen.dart';

/// Luxury Floating Bottom Navigation Container adapting to Dark and Light modes
/// Strict Visual Order: [ Home (Left) | Clinics | Requests | Profile (Right) ]
class MainNavScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localeService = LocaleService();
    final isDark = AppColors.isDark(context);

    final screens = [
      HomeScreen(
        onNavigateToClinics: (categoryFilter) {
          Navigator.push(
            context,
            LuxuryPageRoute(
              page: ClinicsListScreen(initialCategory: categoryFilter),
            ),
          );
        },
      ),
      const ClinicsListScreen(),
      const MyRequestsScreen(),
      ProfileScreen(
        onNavigateToRequests: () => _onTabTapped(2),
      ),
    ];

    return ListenableBuilder(
      listenable: localeService,
      builder: (context, _) {
        return Directionality(
          textDirection: localeService.textDirection,
          child: Scaffold(
            backgroundColor: AppColors.bg(context),
            extendBody: true,
            body: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
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
                // Enforce strictly visual Left-to-Right: [ Home | Clinics | Requests | Profile ]
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _FloatingNavItem(
                        index: 0,
                        selectedIndex: _currentIndex,
                        icon: Icons.space_dashboard_outlined,
                        activeIcon: Icons.space_dashboard_rounded,
                        label: localeService.tr('nav_home'),
                        onTap: () => _onTabTapped(0),
                      ),
                      _FloatingNavItem(
                        index: 1,
                        selectedIndex: _currentIndex,
                        icon: Icons.domain_outlined,
                        activeIcon: Icons.domain_rounded,
                        label: localeService.tr('nav_clinics'),
                        onTap: () => _onTabTapped(1),
                      ),
                      _FloatingNavItem(
                        index: 2,
                        selectedIndex: _currentIndex,
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long_rounded,
                        label: localeService.tr('nav_requests'),
                        onTap: () => _onTabTapped(2),
                      ),
                      _FloatingNavItem(
                        index: 3,
                        selectedIndex: _currentIndex,
                        icon: Icons.person_outline_rounded,
                        activeIcon: Icons.person_rounded,
                        label: localeService.tr('nav_profile'),
                        onTap: () => _onTabTapped(3),
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

class _FloatingNavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _FloatingNavItem({
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
          padding: const EdgeInsets.symmetric(vertical: 7),
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
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 20.5,
                  color: isSelected
                      ? AppColors.accentChampagne
                      : (isDark ? AppColors.silverMuted : AppColors.lightTextMuted),
                ),
              ),
              const SizedBox(height: 3.5),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? (isDark ? AppColors.silverPrimary : AppColors.primarySoftNavy)
                      : (isDark ? AppColors.silverMuted : AppColors.lightTextMuted),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10.5,
                  letterSpacing: isSelected ? 0.15 : 0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
