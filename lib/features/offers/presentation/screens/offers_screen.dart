import 'package:aesthetic_way/core/theme/patient_design.dart';
import '../widgets/patient_offer_card.dart';
import '../offer_actions.dart';
import 'package:aesthetic_way/core/data/paged_collection.dart';
import 'package:aesthetic_way/core/widgets/pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/widgets/luxury_error_view.dart';
import 'package:aesthetic_way/core/widgets/luxury_loading_skeleton.dart';
import 'package:aesthetic_way/core/widgets/luxury_empty_state.dart';
import 'package:aesthetic_way/features/offers/models/offer_model.dart';
import 'package:aesthetic_way/features/offers/data/offers_repository.dart';
import '../../../clinics/data/clinics_repository.dart';

/// Screen 1/8: Exclusive Aesthetic Offers & Packages
/// Powered by live API: GET /api/v1/offers/
class OffersScreen extends StatefulWidget {
  final List<OfferModel>? initialOffers;
  final ClinicsRepository? clinicsRepository;
  final OffersRepository? repository;

  const OffersScreen({
    super.key,
    this.initialOffers,
    this.clinicsRepository,
    this.repository,
  });

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  late final OffersRepository _offersRepository =
      widget.repository ?? OffersRepository();

  final ScrollController _scrollController = ScrollController();
  late final PagedCollection<OfferModel> _paging;
  List<OfferModel>? get _offers => _paging.items;
  bool get _isLoading => _paging.isLoading && _paging.items.isEmpty;
  String? get _errorMessage => _paging.items.isEmpty ? _paging.error : null;
  void _pageChanged() {
    if (mounted) setState(() {});
  }

  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paging = PagedCollection<OfferModel>(
      loader: (page, q) => _offersRepository.getOffers(
        search: q['search'] as String?,
        page: page,
        pageSize: 20,
      ),
      keyOf: (item) => item.id,
    )..addListener(_pageChanged);
    _scrollController.addListener(_onScroll);
    if (widget.initialOffers != null) {
      _paging.items.addAll(widget.initialOffers!.take(20));
      _loadOffers();
    } else {
      _loadOffers();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _paging.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 250) {
      _loadMoreOffers();
    }
  }

  Future<void> _loadOffers() =>
      _paging.refresh(query: {'search': _searchQuery});

  Future<void> _loadMoreOffers() => _paging.loadMore();

  void _onSearchChanged(String value) {
    _searchQuery = value.trim();
    _paging.search({'search': _searchQuery});
  }

  @override
  Widget build(BuildContext context) => PatientDesign(builder: _buildPatient);

  Widget _buildPatient(BuildContext context) {
    final loc = LocaleService();
    final isDark = AppColors.isDark(context);

    final List<OfferModel> filteredOffers = _offers ?? [];

    return ListenableBuilder(
      listenable: loc,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            automaticallyImplyLeading: false,
            title: Text(
              loc.tr('category_offers_title'),
              style: PatientDesign.heading(context, size: 23).copyWith(
                color: isDark
                    ? AppColors.silverPrimary
                    : AppColors.lightTextPrimary,
                fontSize: 16,
              ),
            ),
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: isDark
                          ? AppColors.silverPrimary
                          : AppColors.lightTextPrimary,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
          ),
          body: PagedScrollBoundary(
            onLoadMore: _paging.loadMore,
            child: LuxuryRefreshIndicator(
              onRefresh: _loadOffers,
              child: Column(
                children: [
                  // Search Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                        controller: _searchController,
                        style: TextStyle(
                          color: AppColors.text(context),
                          fontSize: 13.5,
                        ),
                        onChanged: _onSearchChanged,
                        onSubmitted: (_) => _loadOffers(),
                        decoration: InputDecoration(
                          hintText: loc.isArabic
                              ? 'ابحث في العروض التجميلية والعيادات...'
                              : 'Search offers & clinics...',
                          hintStyle: TextStyle(
                            color: AppColors.text(
                              context,
                            ).withValues(alpha: 0.68),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.mutedText(context),
                            size: 18,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    size: 16,
                                    color: AppColors.mutedText(context),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                    _loadOffers();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Offers Content Area
                  Expanded(
                    child: _isLoading
                        ? const LuxuryListSkeleton(
                            itemCount: 4,
                            cardHeight: 140,
                          )
                        : _errorMessage != null && (_offers?.isEmpty ?? true)
                        ? LuxuryErrorView(
                            message: _errorMessage,
                            onRetry: _loadOffers,
                          )
                        : filteredOffers.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.10,
                              ),
                              LuxuryEmptyState(
                                icon: Icons.local_offer_outlined,
                                title: loc.isArabic
                                    ? 'لا توجد باقات عروض حالياً'
                                    : 'No offers currently available',
                                subtitle: loc.isArabic
                                    ? 'ترقبوا عروض وخصومات مميزة من أفضل العيادات قريباً'
                                    : 'Stay tuned for exclusive offers from premier clinics soon',
                                actionLabel: loc.isArabic ? 'تحديث' : 'Refresh',
                                onAction: _loadOffers,
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: filteredOffers.length + 1,
                            itemBuilder: (context, index) {
                              if (index >= filteredOffers.length) {
                                return PaginationFooter(
                                  loading: _paging.isLoadingMore,
                                  hasMore: _paging.hasMore,
                                  error: _paging.error,
                                  onLoadMore: _paging.loadMore,
                                );
                              }
                              final offer = filteredOffers[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: PatientOfferCard(
                                  offer: offer,
                                  onInquiryAction: (action) => openOfferClinic(
                                    context,
                                    offer,
                                    action,
                                    widget.clinicsRepository ??
                                        ClinicsRepository(),
                                    inquire: true,
                                  ),
                                  onClinicAction: (action) => openOfferClinic(
                                    context,
                                    offer,
                                    action,
                                    widget.clinicsRepository ??
                                        ClinicsRepository(),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
