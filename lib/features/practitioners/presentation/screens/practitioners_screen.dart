import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/data/mock_data.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioner_profile_screen.dart';

/// Screen 3 & 4: Practitioners Directory (Doctors & Skin Experts)
class PractitionersScreen extends StatefulWidget {
  final String? initialRoleFilter; // 'all', 'doctors', 'skin_experts'

  const PractitionersScreen({super.key, this.initialRoleFilter});

  @override
  State<PractitionersScreen> createState() => _PractitionersScreenState();
}

class _PractitionersScreenState extends State<PractitionersScreen> {
  late String _selectedRole;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRoleFilter ?? 'all';
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final mockData = MockDataService();
    final isDark = AppColors.isDark(context);

    final isSkinExpertsOnly = widget.initialRoleFilter == 'skin_experts';
    final isDoctorsOnly = widget.initialRoleFilter == 'doctors';

    String screenTitle = loc.tr('category_doctors_title');
    if (isSkinExpertsOnly) {
      screenTitle = loc.tr('category_skin_experts_title');
    } else if (_selectedRole == 'skin_experts') {
      screenTitle = loc.tr('category_skin_experts_title');
    }

    final roleTabs = [
      {'id': 'all', 'label': loc.tr('filter_all_roles')},
      {'id': 'doctors', 'label': loc.tr('filter_doctors')},
      {'id': 'skin_experts', 'label': loc.tr('filter_skin_experts')},
    ];

    final filteredList = mockData.practitioners.where((p) {
      if (isSkinExpertsOnly || _selectedRole == 'skin_experts') {
        final isExpert = p.type == PractitionerType.nurse ||
            p.type == PractitionerType.licensedProfessional ||
            p.specialtyAr.contains('بشرة') ||
            p.specialtyAr.contains('ليزر') ||
            p.specialtyEn.toLowerCase().contains('skin') ||
            p.specialtyEn.toLowerCase().contains('laser');
        if (!isExpert) return false;
      } else if (isDoctorsOnly || _selectedRole == 'doctors') {
        if (p.type != PractitionerType.doctor) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.nameAr.toLowerCase().contains(q) ||
            p.nameEn.toLowerCase().contains(q) ||
            p.specialtyAr.toLowerCase().contains(q) ||
            p.clinicNameAr.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return ListenableBuilder(
      listenable: Listenable.merge([loc, mockData]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              screenTitle,
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                fontSize: 15.5,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border(context), width: 0.8),
                  ),
                  child: TextField(
                    style: TextStyle(color: AppColors.text(context), fontSize: 13.5),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: loc.tr('practitioners_search_hint'),
                      hintStyle: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.mutedText(context), size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Role Tabs (If not strictly filtered from category icon)
              if (!isSkinExpertsOnly && !isDoctorsOnly)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: roleTabs.map((tab) {
                      final isSelected = _selectedRole == tab['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            tab['label']!,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? AppColors.backgroundDeep : AppColors.mutedText(context),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.accentChampagne,
                          backgroundColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                          side: BorderSide(
                            color: isSelected ? AppColors.accentChampagne : AppColors.border(context),
                            width: 0.8,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          onSelected: (_) {
                            setState(() {
                              _selectedRole = tab['id']!;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 6),

              // Practitioners List
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Text(
                          loc.isArabic ? 'لا يوجد ممارسون مطابقون' : 'No practitioners found',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final practitioner = filteredList[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: LuxuryCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  LuxuryPageRoute(page: PractitionerProfileScreen(practitioner: practitioner)),
                                );
                              },
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      practitioner.avatarUrl,
                                      width: 65,
                                      height: 65,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 65,
                                        height: 65,
                                        color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                        child: const Icon(Icons.person_rounded, size: 30, color: AppColors.accentChampagne),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            PractitionerBadge(type: practitioner.type),
                                            const Spacer(),
                                            Row(
                                              children: [
                                                const Icon(Icons.star_rounded, size: 14, color: AppColors.accentChampagne),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${practitioner.rating}',
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          loc.isArabic ? practitioner.nameAr : practitioner.nameEn,
                                          style: TextStyle(
                                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          loc.isArabic ? practitioner.specialtyAr : practitioner.specialtyEn,
                                          style: TextStyle(color: AppColors.mutedText(context), fontSize: 11.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          loc.isArabic ? practitioner.clinicNameAr : (practitioner.clinicNameEn ?? practitioner.clinicNameAr),
                                          style: const TextStyle(color: AppColors.accentChampagne, fontSize: 11, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.accentChampagne),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
