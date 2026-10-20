import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
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

  late final PagedCollection<PractitionerModel> _paging;
  List<PractitionerModel> get _practitioners => _paging.items;
  bool get _isLoading => _paging.isLoading;
  String? get _errorMessage => _paging.items.isEmpty ? _paging.error : null;
  void _pageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? PractitionersRepository();
    _selectedRole = widget.initialRoleFilter ?? 'all';
    _paging = PagedCollection<PractitionerModel>(
      loader: (page, q) => _repository.getPractitioners(
        types: q['types'] as String?,
        type: q['type'] as String?,
        search: q['search'] as String?,
        page: page,
        pageSize: 20,
      ),
      keyOf: (item) => item.id,
    )..addListener(_pageChanged);
    _loadPractitioners();
  }

  @override
  void dispose() {
    _paging.dispose();
    super.dispose();
  }

  Future<void> _loadPractitioners() => _paging.refresh(
    query: {'search': _searchQuery, 'type': _roleType, 'types': _roleTypes},
  );

  void _onSearchChanged(String value) {
    _searchQuery = value.trim();
    _paging.search({
      'search': _searchQuery,
      'type': _roleType,
      'types': _roleTypes,
    });
  }

  String? get _roleTypes =>
      _selectedRole == 'skin_experts' ? 'nurse,licensed_professional' : null;
  String? get _roleType => switch (_selectedRole) {
    'doctors' || 'doctor' => 'doctor',
    'nurse' => 'nurse',
    'licensed_professional' => 'licensed_professional',
    _ => null,
  };

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
        final isExpert =
            p.type == PractitionerType.nurse ||
            p.type == PractitionerType.licensedProfessional;
        if (!isExpert) return false;
      } else if (isDoctorsOnly || _selectedRole == 'doctors') {
        if (p.type != PractitionerType.doctor) return false;
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
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 15.5,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
                size: 18,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh_rounded,
                  color: isDark
                      ? AppColors.silverSecondary
                      : AppColors.lightTextPrimary,
                  size: 20,
                ),
                onPressed: _isLoading ? null : _loadPractitioners,
              ),
            ],
          ),
          body: PagedScrollBoundary(
            onLoadMore: _paging.loadMore,
            child: Column(
              children: [
                // Search Input
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.border(context),
                        width: 0.8,
                      ),
                    ),
                    child: TextField(
                      style: TextStyle(
                        color: AppColors.text(context),
                        fontSize: 13.5,
                      ),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: loc.tr('practitioners_search_hint'),
                        hintStyle: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 12,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: AppColors.mutedText(context),
                          size: 18,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                ),

                // Role Tabs
                if (!isSkinExpertsOnly && !isDoctorsOnly)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
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
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppColors.backgroundDeep
                                    : AppColors.text(context),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.accentChampagne,
                            backgroundColor: isDark
                                ? AppColors.cardSurface
                                : AppColors.lightCardSurface,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.accentChampagne
                                  : AppColors.border(context),
                              width: 0.8,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedRole = tab['id']!;
                              });
                              _paging.search({
                                'search': _searchQuery,
                                'type': _roleType,
                                'types': _roleTypes,
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
                            child: CircularProgressIndicator(
                              color: AppColors.accentChampagne,
                            ),
                          )
                        : _errorMessage != null
                        ? ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 60),
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Colors.amber,
                                size: 44,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                loc.isArabic
                                    ? 'تعذر تحميل قائمة الأطباء والممارسين'
                                    : 'Failed to load practitioners',
                                style: AppTypography.cardTitle.copyWith(
                                  color: isDark
                                      ? AppColors.silverPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _loadPractitioners,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    loc.isArabic ? 'إعادة المحاولة' : 'Retry',
                                  ),
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
                                  loc.isArabic
                                      ? 'لا يوجد أطباء أو خبراء مطابقون'
                                      : 'No matching practitioners found',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.mutedText(context),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: filteredList.length + 1,
                            itemBuilder: (context, index) {
                              if (index >= filteredList.length) {
                                return PaginationFooter(
                                  loading: _paging.isLoadingMore,
                                  hasMore: _paging.hasMore,
                                  error: _paging.error,
                                  onLoadMore: _paging.loadMore,
                                );
                              }

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                PractitionerBadge(
                                                  type: p.type,
                                                  hasKnownType: p.hasKnownType,
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 12,
                                                  color: AppColors.mutedText(
                                                    context,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              loc.isArabic
                                                  ? p.nameAr
                                                  : p.nameEn,
                                              style: AppTypography.cardTitle
                                                  .copyWith(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w800,
                                                    color: isDark
                                                        ? AppColors
                                                              .silverPrimary
                                                        : AppColors
                                                              .lightTextPrimary,
                                                  ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              loc.isArabic
                                                  ? p.specialtyAr
                                                  : p.specialtyEn,
                                              style: AppTypography.caption
                                                  .copyWith(
                                                    color: AppColors.goldText(
                                                      context,
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 11.5,
                                                  ),
                                            ),
                                            if (p.clinicNameAr.isNotEmpty ||
                                                (p.clinicNameEn?.isNotEmpty ??
                                                    false)) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.apartment_rounded,
                                                    size: 13,
                                                    color: AppColors.mutedText(
                                                      context,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      loc.isArabic
                                                          ? (p
                                                                    .clinicNameAr
                                                                    .isNotEmpty
                                                                ? p.clinicNameAr
                                                                : (p.clinicNameEn ??
                                                                      ''))
                                                          : (p.clinicNameEn ??
                                                                p.clinicNameAr),
                                                      style: AppTypography
                                                          .caption
                                                          .copyWith(
                                                            color:
                                                                AppColors.mutedText(
                                                                  context,
                                                                ),
                                                            fontSize: 11,
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
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
          ),
        );
      },
    );
  }
}
