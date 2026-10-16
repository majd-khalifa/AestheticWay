import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/luxury_image.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/widgets/luxury_animations.dart';
import 'package:aesthetic_way/features/practitioners/data/practitioners_repository.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/practitioners/presentation/screens/practitioner_profile_screen.dart';

/// Screen 3 & 4: Practitioners Directory (Doctors & Skin Experts) — Live API (/api/v1/practitioners/)
class PractitionersScreen extends StatefulWidget {
  final String? initialRoleFilter; // 'all', 'doctors', 'skin_experts'
  final PractitionersRepository? repository;

  const PractitionersScreen({
    super.key,
    this.initialRoleFilter,
    this.repository,
  });

  @override
  State<PractitionersScreen> createState() => _PractitionersScreenState();
}

class _PractitionersScreenState extends State<PractitionersScreen> {
  late final PractitionersRepository _repository;
  late String _selectedRole;
  String _searchQuery = '';
  Timer? _debounce;

  List<PractitionerModel> _practitioners = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PractitionersRepository();
    _selectedRole = widget.initialRoleFilter ?? 'all';
    _loadPractitioners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPractitioners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.getPractitioners(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (!mounted) return;
      setState(() {
        _practitioners = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = val.trim();
      });
      _loadPractitioners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final isSkinExpertsOnly = widget.initialRoleFilter == 'skin_experts';
    final isDoctorsOnly = widget.initialRoleFilter == 'doctors';

    String screenTitle = loc.tr('category_doctors_title');
    if (isSkinExpertsOnly || _selectedRole == 'skin_experts') {
      screenTitle = loc.tr('category_skin_experts_title');
    }

    final roleTabs = [
      {'id': 'all', 'label': loc.tr('filter_all_roles')},
      {'id': 'doctors', 'label': loc.tr('filter_doctors')},
      {'id': 'skin_experts', 'label': loc.tr('filter_skin_experts')},
    ];

    final filteredList = _practitioners.where((p) {
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
            p.specialtyEn.toLowerCase().contains(q) ||
            p.clinicNameAr.toLowerCase().contains(q) ||
            (p.clinicNameEn?.toLowerCase().contains(q) ?? false);
      }
      return true;
    }).toList();

    return ListenableBuilder(
      listenable: loc,
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
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isDark ? AppColors.silverSecondary : AppColors.lightTextPrimary,
                  size: 20,
                ),
                onPressed: _isLoading ? null : _loadPractitioners,
              ),
            ],
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
                    onChanged: _onSearchChanged,
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

              // Role Tabs
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
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.backgroundDeep : AppColors.text(context),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.accentChampagne,
                          backgroundColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                          side: BorderSide(
                            color: isSelected ? AppColors.accentChampagne : AppColors.border(context),
                            width: 0.8,
                          ),
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

              // Directory List
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.accentChampagne,
                  onRefresh: _loadPractitioners,
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: AppColors.accentChampagne),
                        )
                      : _errorMessage != null
                          ? ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                const SizedBox(height: 60),
                                const Icon(Icons.error_outline_rounded, color: Colors.amber, size: 44),
                                const SizedBox(height: 12),
                                Text(
                                  loc.isArabic ? 'تعذر تحميل قائمة الأطباء والممارسين' : 'Failed to load practitioners',
                                  style: AppTypography.cardTitle.copyWith(
                                    color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: _loadPractitioners,
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: Text(loc.isArabic ? 'إعادة المحاولة' : 'Retry'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentChampagne,
                                      foregroundColor: AppColors.backgroundDeep,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : filteredList.isEmpty
                              ? ListView(
                                  children: [
                                    const SizedBox(height: 100),
                                    Center(
                                      child: Text(
                                        loc.isArabic ? 'لا يوجد أطباء أو خبراء مطابقون' : 'No matching practitioners found',
                                        style: AppTypography.bodyMedium.copyWith(color: AppColors.mutedText(context)),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  itemCount: filteredList.length,
                                  itemBuilder: (context, index) {
                                    final p = filteredList[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: LuxuryCard(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            LuxuryPageRoute(
                                              page: PractitionerProfileScreen(
                                                practitioner: p,
                                                practitionersRepository: _repository,
                                              ),
                                            ),
                                          );
                                        },
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            LuxuryImage(
                                              imageUrl: p.avatarUrl,
                                              fallbackLogoUrl: p.clinicLogoUrl,
                                              width: 68,
                                              height: 68,
                                              borderRadius: BorderRadius.circular(14),
                                              placeholderIcon: Icons.person_rounded,
                                              iconSize: 30,
                                            ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      PractitionerBadge(type: p.type),
                                                      Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.mutedText(context)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    loc.isArabic ? p.nameAr : p.nameEn,
                                                    style: AppTypography.cardTitle.copyWith(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.w800,
                                                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    loc.isArabic ? p.specialtyAr : p.specialtyEn,
                                                    style: AppTypography.caption.copyWith(
                                                      color: AppColors.accentChampagne,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 11.5,
                                                    ),
                                                  ),
                                                  if (p.clinicNameAr.isNotEmpty || (p.clinicNameEn?.isNotEmpty ?? false)) ...[
                                                    const SizedBox(height: 6),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.apartment_rounded, size: 13, color: AppColors.mutedText(context)),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            loc.isArabic
                                                                ? (p.clinicNameAr.isNotEmpty ? p.clinicNameAr : (p.clinicNameEn ?? ''))
                                                                : (p.clinicNameEn ?? p.clinicNameAr),
                                                            style: AppTypography.caption.copyWith(
                                                              color: AppColors.mutedText(context),
                                                              fontSize: 11,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
