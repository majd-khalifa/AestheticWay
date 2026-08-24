import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_dashboard_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_leads_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_offers_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_profile_screen.dart';

/// Clinic Partner Navigation Shell with 4 Tabs: Dashboard, Leads, Offers, Profile
class ClinicMainNavScreen extends StatefulWidget {
  final int initialIndex;

  const ClinicMainNavScreen({super.key, this.initialIndex = 0});

  @override
  State<ClinicMainNavScreen> createState() => _ClinicMainNavScreenState();
}

class _ClinicMainNavScreenState extends State<ClinicMainNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final clinicService = ClinicPortalService();
    final isDark = AppColors.isDark(context);

    final screens = [
      ClinicDashboardScreen(onNavigateToLeads: () => _onTabSelected(1), onNavigateToOffers: () => _onTabSelected(2)),
      const ClinicLeadsScreen(),
      const ClinicOffersScreen(),
      const ClinicProfileScreen(),
    ];

    return ListenableBuilder(
      listenable: Listenable.merge([loc, clinicService]),
      builder: (context, _) {
        final newLeadsCount = clinicService.newLeadsCount;

        return Scaffold(
          backgroundColor: AppColors.bg(context),
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundBase : AppColors.lightCardSurface,
              border: Border(
                top: BorderSide(
                  color: AppColors.border(context),
                  width: 0.8,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.accentChampagne,
              unselectedItemColor: AppColors.mutedText(context),
              selectedFontSize: 11.5,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.dashboard_outlined, size: 22),
                  activeIcon: const Icon(Icons.dashboard_rounded, size: 22),
                  label: loc.tr('clinic_nav_dashboard'),
                ),
                BottomNavigationBarItem(
                  icon: Badge(
                    isLabelVisible: newLeadsCount > 0,
                    label: Text('$newLeadsCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.accentChampagne,
                    textColor: AppColors.backgroundDeep,
                    child: const Icon(Icons.mark_email_unread_outlined, size: 22),
                  ),
                  activeIcon: Badge(
                    isLabelVisible: newLeadsCount > 0,
                    label: Text('$newLeadsCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    backgroundColor: AppColors.accentChampagne,
                    textColor: AppColors.backgroundDeep,
                    child: const Icon(Icons.mark_email_read_rounded, size: 22),
                  ),
                  label: loc.tr('clinic_nav_leads'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.local_offer_outlined, size: 22),
                  activeIcon: const Icon(Icons.local_offer_rounded, size: 22),
                  label: loc.tr('clinic_nav_offers'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.storefront_outlined, size: 22),
                  activeIcon: const Icon(Icons.storefront_rounded, size: 22),
                  label: loc.tr('clinic_nav_profile'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
