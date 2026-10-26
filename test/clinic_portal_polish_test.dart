import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/widgets/luxury_image_picker_field.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/screens/clinic_profile_screen.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_category_field.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_editorial_header.dart';
import 'package:aesthetic_way/features/clinic_portal/presentation/widgets/clinic_location_selector.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'package:aesthetic_way/features/clinics/models/clinic_model.dart';
import 'package:aesthetic_way/features/treatments/models/category_model.dart';
import 'products_articles_live_test.dart' show FakeApiClient;

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    LocaleService().setLanguage(AppLanguage.english);
    ClinicPortalService().resetTestingState();
  });
  tearDown(() => ClinicPortalService().resetTestingState());
  setUpAll(() async {
    const fontPath = String.fromEnvironment('PREVIEW_FONT');
    if (fontPath.isNotEmpty) {
      for (final family in ['PreviewSans', 'PreviewArabic', 'serif']) {
        await (FontLoader(family)..addFont(
              File(
                family == 'PreviewArabic'
                    ? fontPath
                    : const String.fromEnvironment('PREVIEW_LATIN_FONT'),
              ).readAsBytes().then((b) => ByteData.sublistView(b)),
            ))
            .load();
      }
      const icons = String.fromEnvironment('PREVIEW_ICON_FONT');
      if (icons.isNotEmpty) {
        await (FontLoader('MaterialIcons')..addFont(
              File(icons).readAsBytes().then((b) => ByteData.sublistView(b)),
            ))
            .load();
      }
    }
  });

  testWidgets(
    'profile reflects a canonical clinic update without reopening the screen',
    (tester) async {
      final service = ClinicPortalService()..enableMockMode();
      final initial = service.activeClinic.copyWith(
        nameEn: 'Before saving',
        logoUrl: '',
        coverImageUrl: '',
        latitude: 0,
        longitude: 0,
      );
      service.setActiveClinicForTesting(initial);
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ClinicProfileScreen(),
        ),
      );
      expect(find.text('Before saving'), findsOneWidget);
      service.setActiveClinicForTesting(
        initial.copyWith(nameEn: 'Server confirmed name'),
      );
      await tester.pump();
      expect(find.text('Server confirmed name'), findsOneWidget);
      expect(find.text('Before saving'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'location sends coordinates and generated map link through service and repository',
    (tester) async {
      Map<String, dynamic>? payload;
      final api = FakeApiClient(
        onGet: (_, _) => {},
        onPatch: (path, data) {
          expect(path, 'clinic-portal/profile/');
          payload = Map<String, dynamic>.from(data as Map);
          return {
            'id': 'clinic-a',
            'name_en': 'Clinic',
            'name_ar': 'العيادة',
            ...payload!,
          };
        },
      );
      final service = ClinicPortalService();
      service.setCatalogRepositoryForTesting(
        ClinicCatalogRepository(apiClient: api),
      );
      const location = ClinicLocationSelection(
        city: 'Dubai',
        addressAr: 'جميرا، مبنى ٣',
        addressEn: 'Jumeirah, building 3',
        latitude: 25.231512345,
        longitude: 55.324212345,
      );
      await service.updateClinicProfile(
        nameAr: 'العيادة',
        nameEn: 'Clinic',
        descriptionAr: '',
        descriptionEn: '',
        phone: '+971501234567',
        whatsapp: '+971501234567',
        city: location.city,
        emirate: location.city,
        addressAr: location.addressAr,
        addressEn: location.addressEn,
        latitude: location.latitude,
        longitude: location.longitude,
        googleMapsUrl: location.googleMapsUrl,
      );
      expect(payload!['latitude'], '25.2315123');
      expect(payload!['longitude'], '55.3242123');
      expect(payload!['emirate'], 'Dubai');
      expect(
        payload!['google_maps_url'],
        'https://www.google.com/maps/search/?api=1&query=25.2315123,55.3242123',
      );
      expect(payload!.containsKey('logo'), isFalse);
      expect(payload!.containsKey('cover_image'), isFalse);
      expect(service.activeClinic.latitude, closeTo(25.2315123, .00000001));
      expect(service.activeClinic.addressEn, location.addressEn);
    },
  );

  test('location summary never renders orphan separators', () {
    expect(
      clinicLocationSummary('', ' ', arabic: false),
      'Location not provided',
    );
    expect(clinicLocationSummary('Dubai', '', arabic: false), 'Dubai');
    expect(clinicLocationSummary('', 'Jumeirah', arabic: false), 'Jumeirah');
    expect(
      clinicLocationSummary('Dubai', 'Jumeirah', arabic: false),
      'Dubai • Jumeirah',
    );
    expect(ClinicLocationSelection.validCoordinates(double.nan, 55), isFalse);
    expect(ClinicLocationSelection.validCoordinates(0, 0), isFalse);
    expect(ClinicLocationSelection.validCoordinates(91, 55), isFalse);
  });

  testWidgets('loaded category dropdown selects the category UUID', (
    tester,
  ) async {
    final categories = [
      CategoryModel.fromJson({
        'id': 'skin-id',
        'name_en': 'Skin care',
        'name_ar': 'العناية بالبشرة',
      }),
      CategoryModel.fromJson({
        'id': 'laser-id',
        'name_en': 'Laser',
        'name_ar': 'الليزر',
      }),
    ];
    CategoryModel? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClinicCategoryField(
            categories: categories,
            value: null,
            valueLabel: null,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Laser').last);
    await tester.pumpAndSettle();
    expect(selected?.id, 'laser-id');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'area preview requires explicit exact-pin confirmation and cancel returns no selection',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      ClinicLocationSelection? selected;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await showClinicLocationSelector(
                    context,
                    city: 'Dubai',
                    addressAr: 'العنوان',
                    addressEn: 'Existing address',
                    latitude: 0,
                    longitude: 0,
                  );
                },
                child: const Text('Choose'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      final locationScroll = find
          .descendant(
            of: find.byKey(const ValueKey('clinic-location-form')),
            matching: find.byType(Scrollable),
          )
          .first;
      Future<void> scrollLocationToEnd() async {
        for (var i = 0; i < 4; i++) {
          final state = tester.state<ScrollableState>(locationScroll);
          state.position.jumpTo(state.position.maxScrollExtent);
          await tester.pump();
        }
      }

      await scrollLocationToEnd();
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text('Use This Location'),
                matching: find.byWidgetPredicate((w) => w is FilledButton),
              ),
            )
            .onPressed,
        isNull,
      );
      tester.state<ScrollableState>(locationScroll).position.jumpTo(0);
      await tester.pump();
      // A catalog district is not an exact clinic entrance. Enter explicit UAE
      // coordinates rather than adopting a removed hardcoded district centroid.
      await tester.enterText(
        find.byKey(const ValueKey('clinic-address-search')),
        '25.2315, 55.3242',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final confirm = find.text('Use This Location');
      await scrollLocationToEnd();
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(of: confirm, matching: find.byType(FilledButton)),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.text('Confirm pin is the exact clinic location'),
      );
      await tester.tap(find.text('Confirm pin is the exact clinic location'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm entrance'));
      await tester.pumpAndSettle();
      await scrollLocationToEnd();
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(selected?.latitude, 25.2315);
      expect(selected?.longitude, 55.3242);
      expect(selected?.addressEn, 'Existing address');
      selected = null;
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      final cancel = find.text('Cancel');
      await scrollLocationToEnd();
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    for (final arabic in [false, true]) {
      final mode = '${dark ? 'dark' : 'light'}_${arabic ? 'ar' : 'en'}';
      testWidgets(
        '320px large text header, circular picker and catalog row $mode',
        (tester) async {
          LocaleService().setLanguage(
            arabic ? AppLanguage.arabic : AppLanguage.english,
          );
          await tester.binding.setSurfaceSize(const Size(320, 1500));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final clinic = ClinicModel.fromJson({
            'name_en': 'Lumiere Skin Clinics',
            'name_ar': 'عيادات لوميير للبشرة',
            'city': 'Dubai',
            'address_en': 'Jumeirah',
            'address_ar': 'جميرا',
            'subscription_tier': 'vip',
          });
          final boundary = GlobalKey();
          var theme = dark ? AppTheme.darkTheme : AppTheme.lightTheme;
          if (const String.fromEnvironment('PREVIEW_FONT').isNotEmpty) {
            theme = theme.copyWith(
              textTheme: theme.textTheme.apply(
                fontFamily: arabic ? 'PreviewArabic' : 'PreviewSans',
                fontFamilyFallback: const ['PreviewSans'],
              ),
            );
          }
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 1500),
                  textScaler: TextScaler.linear(1.6),
                ),
                child: Directionality(
                  textDirection: arabic ? TextDirection.rtl : TextDirection.ltr,
                  child: Scaffold(
                    body: SingleChildScrollView(
                      child: RepaintBoundary(
                        key: boundary,
                        child: ColoredBox(
                          color: theme.scaffoldBackgroundColor,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClinicEditorialHeader(
                                clinic: clinic,
                                onEdit: () {},
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: LuxuryImagePickerField(
                                  label: arabic
                                      ? 'صورة الممارس'
                                      : 'Practitioner Photo',
                                  height: 104,
                                  isCircular: true,
                                  onImageSelected: (_) {},
                                ),
                              ),
                              ClinicCatalogMiniRow(
                                title: arabic
                                    ? 'العناية المتقدمة بالبشرة'
                                    : 'Advanced Skin Care',
                                subtitle: arabic
                                    ? 'علاج مخصص لصحة ونضارة البشرة'
                                    : 'Personalised medical aesthetic care',
                                imageUrl: '',
                                icon: Icons.spa_outlined,
                                badge: arabic ? '٧٥٠ درهم' : '750 AED',
                                onEdit: () {},
                                onDelete: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final picker = find.byType(LuxuryImagePickerField);
          final helper = find.descendant(
            of: picker,
            matching: find.text(
              arabic ? 'الكاميرا أو معرض الصور' : 'Camera or Gallery',
            ),
          );
          final zone = find
              .descendant(of: picker, matching: find.byType(GestureDetector))
              .first;
          expect(
            tester.getTopLeft(helper).dy,
            greaterThanOrEqualTo(tester.getBottomLeft(zone).dy),
          );
          const preview = String.fromEnvironment('CLINIC_PREVIEW_DIR');
          if (preview.isNotEmpty) {
            final render =
                boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            await tester.runAsync(() async {
              final image = await render.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(preview).create(recursive: true);
              await File(
                '$preview/clinic_portal_$mode.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        },
      );
    }
  }
}
