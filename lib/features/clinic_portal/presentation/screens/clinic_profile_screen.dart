import 'package:flutter/material.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/theme/app_typography.dart';
import 'package:aesthetic_way/core/theme/theme_service.dart';
import 'package:aesthetic_way/core/widgets/luxury_card.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/tier_badge.dart';
import 'package:aesthetic_way/core/widgets/practitioner_badge.dart';
import 'package:aesthetic_way/core/utils/maps_launcher.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/practitioners/models/practitioner_model.dart';
import 'package:aesthetic_way/features/treatments/models/treatment_model.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/articles/models/article_model.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';

/// Clinic Tab 4: Clinic Profile, Google Maps Linking, Medical Team & Services Manager
class ClinicProfileScreen extends StatelessWidget {
  const ClinicProfileScreen({super.key});

  void _showAddPractitionerDialog(BuildContext context, LocaleService loc) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final specialtyController = TextEditingController();
    final expController = TextEditingController(text: '8');
    final langController = TextEditingController(text: loc.isArabic ? 'العربية، الإنجليزية' : 'Arabic, English');
    final licenseRefController = TextEditingController(text: 'LIC-P-${DateTime.now().millisecondsSinceEpoch % 100000}');
    final bioController = TextEditingController();
    final avatarController = TextEditingController();
    var selectedType = PractitionerType.doctor;
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.border(ctx), width: 0.8)),
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.mutedText(ctx).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.tr('clinic_add_practitioner'),
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Full Name (Required)
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_practitioner_name'),
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 10),

                    // Role / Type Dropdown
                    DropdownButtonFormField<PractitionerType>(
                      initialValue: selectedType,
                      dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                      decoration: InputDecoration(
                        labelText: loc.isArabic ? 'نوع الممارس' : 'Practitioner Type',
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                      items: PractitionerType.values.map((type) {
                        String label;
                        switch (type) {
                          case PractitionerType.doctor:
                            label = loc.tr('role_doctor');
                            break;
                          case PractitionerType.nurse:
                            label = loc.tr('role_nurse');
                            break;
                          case PractitionerType.licensedProfessional:
                            label = loc.tr('role_specialist');
                            break;
                        }
                        return DropdownMenuItem(
                          value: type,
                          child: Text(label, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() {
                            selectedType = v;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Specialty (Required)
                    TextFormField(
                      controller: specialtyController,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_practitioner_specialty'),
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 10),

                    // Years of Experience
                    TextFormField(
                      controller: expController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_doctor_years_exp'),
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Spoken Languages
                    TextFormField(
                      controller: langController,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_doctor_languages'),
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Internal Platform License Reference
                    TextFormField(
                      controller: licenseRefController,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_doctor_license_ref'),
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Short Professional Bio
                    TextFormField(
                      controller: bioController,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_doctor_bio'),
                        hintText: loc.isArabic ? 'نبذة عن الخبرات والشهادات التخصصية...' : 'Brief bio about clinical experience...',
                        hintStyle: TextStyle(color: AppColors.mutedText(ctx), fontSize: 11.5),
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Avatar URL (Optional)
                    TextFormField(
                      controller: avatarController,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_doctor_avatar_opt'),
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SilverButton(
                      label: loc.tr('clinic_add_practitioner'),
                      icon: Icons.check,
                      isFullWidth: true,
                      height: 44,
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final parsedYears = int.tryParse(expController.text.trim()) ?? 5;
                        final langs = langController.text.trim().split(RegExp(r'[,،]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

                        final p = PractitionerModel(
                          id: 'doc-${DateTime.now().millisecondsSinceEpoch}',
                          nameAr: nameController.text.trim(),
                          nameEn: nameController.text.trim(),
                          type: selectedType,
                          specialtyAr: specialtyController.text.trim(),
                          specialtyEn: specialtyController.text.trim(),
                          classificationAr: 'ممارس طبي معتمد',
                          classificationEn: 'Certified Practitioner',
                          licenseAuthority: 'Accredited Specialist',
                          licenseNumber: licenseRefController.text.trim().isNotEmpty ? licenseRefController.text.trim() : 'LIC-P-004812',
                          avatarUrl: avatarController.text.trim().isNotEmpty
                              ? avatarController.text.trim()
                              : 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=300&q=80',
                          yearsOfExperience: parsedYears,
                          rating: 5.0,
                          reviewCount: 1,
                          languages: langs.isNotEmpty ? langs : const ['العربية', 'English'],
                          clinicId: ClinicPortalService().activeClinic.id,
                          clinicNameAr: ClinicPortalService().activeClinic.nameAr,
                          clinicNameEn: ClinicPortalService().activeClinic.nameEn,
                          procedures: const ['استشارة تجميلية متقدمة', 'علاجات النضارة والشد'],
                          proceduresEn: const ['Aesthetic Consultation', 'Rejuvenation Treatments'],
                          aboutAr: bioController.text.trim().isNotEmpty ? bioController.text.trim() : 'كادر طبي معتمد ذو كفاءة وخبرة واسعة.',
                          aboutEn: bioController.text.trim().isNotEmpty ? bioController.text.trim() : 'Certified practitioner with comprehensive clinical experience.',
                        );
                        ClinicPortalService().addPractitioner(p);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.tr('clinic_practitioner_saved')), backgroundColor: AppColors.accentChampagne),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddServiceDialog(BuildContext context, LocaleService loc) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController(text: '750');
    final durationController = TextEditingController(text: '45');
    final targetAreaController = TextEditingController(text: loc.isArabic ? 'الوجه والرقبة' : 'Face & Neck');
    final recoveryController = TextEditingController(text: loc.isArabic ? 'بدون فترة تعافي' : 'Zero Downtime');
    final descController = TextEditingController();
    var selectedCategory = loc.isArabic ? 'علاجات البشرة والليزر' : 'Skin & Laser';
    final isDark = AppColors.isDark(context);

    final categories = loc.isArabic
        ? ['علاجات البشرة والليزر', 'حقن وفيلر ونضارة', 'جراحة تجميلية', 'نحت وتنسيق القوام']
        : ['Skin & Laser', 'Injectables & Fillers', 'Plastic Surgery', 'Body Contouring'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDeep : AppColors.lightCardSurface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.border(ctx), width: 0.8)),
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.mutedText(ctx).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc.tr('clinic_add_service'),
                      style: AppTypography.cardTitle.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Service Name (Required)
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_service_name'),
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accentChampagne, width: 1.4),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 10),

                    // Category Selector Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_service_category'),
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() {
                            selectedCategory = v;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),

                    // Price (AED) & Duration (Minutes) Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: loc.tr('clinic_service_price'),
                              filled: true,
                              fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                              ),
                            ),
                            validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: loc.tr('clinic_service_duration'),
                              filled: true,
                              fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Target Area & Recovery Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: targetAreaController,
                            style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: loc.tr('clinic_service_target_area'),
                              filled: true,
                              fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: recoveryController,
                            style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              labelText: loc.tr('clinic_service_recovery'),
                              filled: true,
                              fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Short Description (Required)
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_service_description'),
                        hintText: loc.isArabic ? 'وصف للمزايا وشروط الجلسة...' : 'Short description of procedure & benefits...',
                        hintStyle: TextStyle(color: AppColors.mutedText(ctx), fontSize: 11.5),
                        filled: true,
                        fillColor: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(ctx), width: 0.8),
                        ),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SilverButton(
                      label: loc.tr('clinic_add_service'),
                      icon: Icons.check,
                      isFullWidth: true,
                      height: 44,
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final durationVal = '${durationController.text.trim()} ${loc.isArabic ? "دقيقة" : "mins"}';

                        final t = TreatmentModel(
                          id: 'treat-${DateTime.now().millisecondsSinceEpoch}',
                          nameAr: nameController.text.trim(),
                          nameEn: nameController.text.trim(),
                          categoryAr: selectedCategory,
                          categoryEn: selectedCategory,
                          descriptionAr: descController.text.trim(),
                          descriptionEn: descController.text.trim(),
                          durationText: durationVal,
                          durationTextEn: durationVal,
                          downtimeText: recoveryController.text.trim().isNotEmpty ? recoveryController.text.trim() : 'بدون فترة تعافي',
                          downtimeTextEn: recoveryController.text.trim().isNotEmpty ? recoveryController.text.trim() : 'Zero Downtime',
                          targetAreaAr: targetAreaController.text.trim().isNotEmpty ? targetAreaController.text.trim() : 'الوجه والرقبة',
                          targetAreaEn: targetAreaController.text.trim().isNotEmpty ? targetAreaController.text.trim() : 'Face & Neck',
                          clinicsCount: 1,
                          imageUrl: 'https://images.unsplash.com/photo-1512290900672-1f02e604ec22?auto=format&fit=crop&w=800&q=80',
                        );
                        ClinicPortalService().addTreatment(t);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.tr('clinic_service_saved')), backgroundColor: AppColors.accentChampagne),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddProductDialog(BuildContext context, LocaleService loc) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final origPriceController = TextEditingController();
    final descController = TextEditingController();
    final imageController = TextEditingController();
    var selectedCategory = loc.isArabic ? 'عناية بالبشرة' : 'Skincare';
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      loc.tr('clinic_add_product'),
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Name
                    TextFormField(
                      controller: nameController,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: '${loc.tr("clinic_product_name")} *',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 12),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: AppColors.surface(ctx),
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_product_category'),
                        prefixIcon: const Icon(Icons.category_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem(value: loc.isArabic ? 'عناية بالبشرة' : 'Skincare', child: Text(loc.tr('product_category_skincare'))),
                        DropdownMenuItem(value: loc.isArabic ? 'مستحضرات علاجية' : 'Cosmeceuticals', child: Text(loc.tr('product_category_cosmeceuticals'))),
                        DropdownMenuItem(value: loc.isArabic ? 'أجهزة منزلية' : 'Home Devices', child: Text(loc.tr('product_category_devices'))),
                        DropdownMenuItem(value: loc.isArabic ? 'واقيات شمس ومكملات' : 'Sun Care & Supplements', child: Text(loc.tr('product_category_sunscreens'))),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Price & Original Price
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                            decoration: InputDecoration(
                              labelText: '${loc.tr("clinic_product_price")} *',
                              prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.accentChampagne, size: 18),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return loc.tr('clinic_validation_required');
                              if (double.tryParse(val.trim()) == null) return loc.isArabic ? 'أدخل رقماً صحيحاً' : 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: origPriceController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                            decoration: InputDecoration(
                              labelText: loc.tr('clinic_product_orig_price'),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: descController,
                      maxLines: 2,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: '${loc.tr("clinic_product_description")} *',
                        prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 12),

                    // Image URL
                    TextFormField(
                      controller: imageController,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_product_image'),
                        prefixIcon: const Icon(Icons.image_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SilverButton(
                      label: loc.tr('clinic_add_product'),
                      icon: Icons.check,
                      isFullWidth: true,
                      height: 44,
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final clinic = ClinicPortalService().activeClinic;
                        final price = double.parse(priceController.text.trim());
                        final origPrice = double.tryParse(origPriceController.text.trim());

                        final p = ProductModel(
                          id: 'prod-${DateTime.now().millisecondsSinceEpoch}',
                          nameAr: nameController.text.trim(),
                          nameEn: nameController.text.trim(),
                          clinicId: clinic.id,
                          clinicNameAr: clinic.nameAr,
                          clinicNameEn: clinic.nameEn,
                          descriptionAr: descController.text.trim(),
                          descriptionEn: descController.text.trim(),
                          price: price,
                          originalPrice: origPrice,
                          imageUrl: imageController.text.trim().isNotEmpty
                              ? imageController.text.trim()
                              : 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=600&q=80',
                          categoryAr: selectedCategory,
                          categoryEn: selectedCategory,
                          isAvailable: true,
                        );

                        ClinicPortalService().addProduct(p);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.tr('clinic_product_saved')), backgroundColor: AppColors.accentChampagne),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddArticleDialog(BuildContext context, LocaleService loc) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final summaryController = TextEditingController();
    final contentController = TextEditingController();
    final imageController = TextEditingController();
    final clinicService = ClinicPortalService();
    final doctors = clinicService.clinicPractitioners.where((p) => p.type == PractitionerType.doctor).toList();
    final defaultDoctor = doctors.isNotEmpty ? doctors.first : (clinicService.clinicPractitioners.isNotEmpty ? clinicService.clinicPractitioners.first : null);
    
    PractitionerModel? selectedDoctor = defaultDoctor;
    var selectedCategory = loc.isArabic ? 'نضارة وتجديد البشرة' : 'Skin Glow & Renewal';
    final isDark = AppColors.isDark(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 20,
              ),
              child: Form(
                key: formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Text(
                      loc.tr('clinic_add_article'),
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    TextFormField(
                      controller: titleController,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: '${loc.tr("clinic_article_title")} *',
                        prefixIcon: const Icon(Icons.article_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 12),

                    // Doctor Author Dropdown
                    if (doctors.isNotEmpty)
                      DropdownButtonFormField<PractitionerModel>(
                        initialValue: selectedDoctor,
                        dropdownColor: AppColors.surface(ctx),
                        style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                        decoration: InputDecoration(
                          labelText: loc.tr('clinic_article_doctor_author'),
                          prefixIcon: const Icon(Icons.person_rounded, color: AppColors.accentChampagne, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: doctors.map((doc) {
                          return DropdownMenuItem(
                            value: doc,
                            child: Text(loc.isArabic ? doc.nameAr : doc.nameEn),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedDoctor = val);
                        },
                      ),
                    const SizedBox(height: 12),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      dropdownColor: AppColors.surface(ctx),
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_article_category'),
                        prefixIcon: const Icon(Icons.category_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem(value: loc.isArabic ? 'نضارة وتجديد البشرة' : 'Skin Glow & Renewal', child: Text(loc.tr('article_category_glow'))),
                        DropdownMenuItem(value: loc.isArabic ? 'الفيلر والبوتوكس' : 'Fillers & Botox', child: Text(loc.tr('article_category_injectables'))),
                        DropdownMenuItem(value: loc.isArabic ? 'علاجات الليزر' : 'Laser Treatments', child: Text(loc.tr('article_category_laser'))),
                        DropdownMenuItem(value: loc.isArabic ? 'الجراحة التجميلية' : 'Plastic Surgery', child: Text(loc.tr('article_category_surgery'))),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Summary
                    TextFormField(
                      controller: summaryController,
                      maxLines: 2,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: '${loc.tr("clinic_article_summary")} *',
                        prefixIcon: const Icon(Icons.short_text_rounded, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 12),

                    // Content
                    TextFormField(
                      controller: contentController,
                      maxLines: 4,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: '${loc.tr("clinic_article_content")} *',
                        prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? loc.tr('clinic_validation_required') : null,
                    ),
                    const SizedBox(height: 12),

                    // Cover Image URL
                    TextFormField(
                      controller: imageController,
                      style: TextStyle(color: AppColors.text(ctx), fontSize: 13),
                      decoration: InputDecoration(
                        labelText: loc.tr('clinic_article_cover'),
                        prefixIcon: const Icon(Icons.image_outlined, color: AppColors.accentChampagne, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SilverButton(
                      label: loc.tr('clinic_add_article'),
                      icon: Icons.check,
                      isFullWidth: true,
                      height: 44,
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final clinic = clinicService.activeClinic;
                        final doc = selectedDoctor ?? defaultDoctor;

                        final art = ArticleModel(
                          id: 'art-${DateTime.now().millisecondsSinceEpoch}',
                          titleAr: titleController.text.trim(),
                          titleEn: titleController.text.trim(),
                          coverImageUrl: imageController.text.trim().isNotEmpty
                              ? imageController.text.trim()
                              : 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
                          summaryAr: summaryController.text.trim(),
                          summaryEn: summaryController.text.trim(),
                          contentAr: contentController.text.trim(),
                          contentEn: contentController.text.trim(),
                          authorDoctorId: doc?.id ?? 'dr-reem',
                          authorDoctorNameAr: doc?.nameAr ?? (loc.isArabic ? 'د. ريم الخالد' : 'Dr. Reem Al Khaled'),
                          authorDoctorNameEn: doc?.nameEn ?? 'Dr. Reem Al Khaled',
                          authorDoctorSpecialtyAr: doc?.specialtyAr ?? 'استشاري جلدية وتجميل',
                          authorDoctorSpecialtyEn: doc?.specialtyEn ?? 'Consultant Dermatologist',
                          authorDoctorAvatar: doc?.avatarUrl ?? 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?auto=format&fit=crop&w=300&q=80',
                          clinicId: clinic.id,
                          clinicNameAr: clinic.nameAr,
                          clinicNameEn: clinic.nameEn,
                          categoryAr: selectedCategory,
                          categoryEn: selectedCategory,
                          publishedAt: DateTime.now(),
                          isPublished: true,
                        );

                        clinicService.addArticle(art);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(loc.tr('clinic_article_saved')), backgroundColor: AppColors.accentChampagne),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocaleService();
    final themeService = ThemeService();
    final clinicService = ClinicPortalService();
    final isDark = AppColors.isDark(context);
    final clinic = clinicService.activeClinic;

    return ListenableBuilder(
      listenable: Listenable.merge([loc, themeService, clinicService]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.bg(context),
          appBar: AppBar(
            backgroundColor: AppColors.bg(context),
            title: Text(
              loc.tr('clinic_nav_profile'),
              style: AppTypography.screenTitle.copyWith(
                color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
              ),
            ),
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Clinic Overview Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            clinic.coverImageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 60,
                              height: 60,
                              color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                              child: const Icon(Icons.apartment_rounded, color: AppColors.accentChampagne),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loc.isArabic ? clinic.nameAr : clinic.nameEn,
                                style: AppTypography.cardTitle.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${clinic.city} • ${loc.isArabic ? clinic.areaAr : clinic.areaEn}',
                                style: AppTypography.caption.copyWith(color: AppColors.mutedText(context)),
                              ),
                              const SizedBox(height: 6),
                              TierBadge(tier: clinic.subscriptionTier),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Text(
                      loc.isArabic ? clinic.descriptionAr : clinic.descriptionEn,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.mutedText(context),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Google Maps Location Card
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.map_outlined, color: AppColors.accentChampagne, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          loc.tr('clinic_maps_config'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      loc.isArabic ? clinic.addressAr : clinic.addressEn,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 12.5,
                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SilverButton(
                      label: loc.tr('open_in_maps'),
                      icon: Icons.directions_outlined,
                      height: 38,
                      onPressed: () {
                        MapsLauncher.openDirections(
                          latitude: clinic.latitude,
                          longitude: clinic.longitude,
                          destinationTitle: loc.isArabic ? clinic.nameAr : clinic.nameEn,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Medical Staff Section
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('clinic_team_title'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne, size: 20),
                          tooltip: loc.tr('clinic_add_practitioner'),
                          onPressed: () => _showAddPractitionerDialog(context, loc),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...clinicService.clinicPractitioners.map((p) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                p.avatarUrl,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 36,
                                  height: 36,
                                  color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                  child: const Icon(Icons.person, size: 20, color: AppColors.accentChampagne),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.isArabic ? p.nameAr : p.nameEn,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  Text(
                                    loc.isArabic ? p.specialtyAr : p.specialtyEn,
                                    style: AppTypography.caption.copyWith(color: AppColors.mutedText(context), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            PractitionerBadge(type: p.type, showIcon: false),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Treatments / Services Section
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('clinic_services_title'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne, size: 20),
                          tooltip: loc.tr('clinic_add_service'),
                          onPressed: () => _showAddServiceDialog(context, loc),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...clinicService.clinicTreatments.map((t) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.spa_outlined, size: 16, color: AppColors.accentChampagne),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                loc.isArabic ? t.nameAr : t.nameEn,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                            ),
                            Text(
                              loc.isArabic ? t.durationText : (t.durationTextEn ?? t.durationText),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.accentChampagne,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Products Section
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('clinic_manage_products'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne, size: 20),
                          tooltip: loc.tr('clinic_add_product'),
                          onPressed: () => _showAddProductDialog(context, loc),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (clinicService.clinicProducts.isEmpty)
                      Text(
                        loc.tr('product_empty'),
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                      )
                    else
                      ...clinicService.clinicProducts.map((p) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  p.imageUrl,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 38,
                                    height: 38,
                                    color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                    child: const Icon(Icons.shopping_bag_outlined, color: AppColors.accentChampagne, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.isArabic ? p.nameAr : p.nameEn,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${p.price.toInt()} ${loc.tr("currency_aed")} • ${loc.isArabic ? p.categoryAr : p.categoryEn}',
                                      style: TextStyle(color: AppColors.accentChampagne, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  p.isAvailable ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  size: 18,
                                  color: p.isAvailable ? const Color(0xFF10B981) : Colors.redAccent,
                                ),
                                tooltip: loc.tr('clinic_product_toggle_avail'),
                                onPressed: () => clinicService.toggleProductAvailability(p.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                onPressed: () => clinicService.deleteProduct(p.id),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Articles Section
              LuxuryCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.tr('clinic_manage_articles'),
                          style: AppTypography.cardTitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accentChampagne, size: 20),
                          tooltip: loc.tr('clinic_add_article'),
                          onPressed: () => _showAddArticleDialog(context, loc),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (clinicService.clinicArticles.isEmpty)
                      Text(
                        loc.tr('article_empty'),
                        style: TextStyle(color: AppColors.mutedText(context), fontSize: 12),
                      )
                    else
                      ...clinicService.clinicArticles.map((art) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  art.coverImageUrl,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 38,
                                    height: 38,
                                    color: isDark ? AppColors.cardSurfaceHover : AppColors.lightCardSurfaceHover,
                                    child: const Icon(Icons.article_outlined, color: AppColors.accentChampagne, size: 18),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.isArabic ? art.titleAr : art.titleEn,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                        color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${loc.tr("article_author_by")}: ${loc.isArabic ? art.authorDoctorNameAr : art.authorDoctorNameEn}',
                                      style: TextStyle(color: AppColors.mutedText(context), fontSize: 10.5),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  art.isPublished ? Icons.public_rounded : Icons.public_off_rounded,
                                  size: 18,
                                  color: art.isPublished ? const Color(0xFF10B981) : Colors.redAccent,
                                ),
                                tooltip: art.isPublished ? (loc.isArabic ? 'منشور' : 'Published') : (loc.isArabic ? 'مسودة' : 'Draft'),
                                onPressed: () => clinicService.toggleArticlePublish(art.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                onPressed: () => clinicService.deleteArticle(art.id),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Theme Switcher Tile
              LuxuryCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      themeService.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      color: AppColors.accentChampagne,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.tr('theme_title'),
                        style: TextStyle(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DropdownButton<ThemeMode>(
                      value: themeService.themeMode,
                      dropdownColor: isDark ? AppColors.cardSurface : AppColors.lightCardSurface,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text(loc.tr('theme_dark'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text(loc.tr('theme_light'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text(loc.tr('theme_system'), style: TextStyle(color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary)),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) themeService.setThemeMode(mode);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Language Switcher Tile
              LuxuryCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.language_rounded, color: AppColors.accentChampagne),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.tr('app_language'),
                        style: TextStyle(
                          color: isDark ? AppColors.silverPrimary : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => loc.toggleLanguage(),
                      child: Text(
                        loc.tr('switch_language'),
                        style: const TextStyle(color: AppColors.accentChampagne, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Logout Clinic Portal Button
              SilverButton(
                label: loc.tr('clinic_logout'),
                icon: Icons.logout_rounded,
                isFullWidth: true,
                height: 46,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}
