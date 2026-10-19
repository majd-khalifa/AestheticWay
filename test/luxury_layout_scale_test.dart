import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aesthetic_way/core/localization/app_locale.dart';
import 'package:aesthetic_way/core/theme/app_theme.dart';
import 'package:aesthetic_way/core/theme/app_colors.dart';
import 'package:aesthetic_way/core/widgets/silver_button.dart';
import 'package:aesthetic_way/core/widgets/bounded_catalog_preview.dart';
import 'package:aesthetic_way/core/widgets/paged_entity_field.dart';
import 'package:aesthetic_way/features/products/data/products_repository.dart';
import 'package:aesthetic_way/features/products/models/product_model.dart';
import 'package:aesthetic_way/features/products/presentation/screens/products_screen.dart';
import 'package:aesthetic_way/features/products/presentation/screens/product_detail_screen.dart';
import 'package:aesthetic_way/features/products/presentation/widgets/brand_product_media.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/login_screen.dart';
import 'package:aesthetic_way/features/auth/presentation/screens/register_screen.dart';
import 'products_articles_live_test.dart' show FakeApiClient;

void main() {
  setUpAll(() async {
    const fontPath = String.fromEnvironment('PREVIEW_FONT');
    if (fontPath.isNotEmpty) {
      for (final family in ['PreviewSans', 'PreviewArabic', 'serif']) {
        final loader = FontLoader(family)
          ..addFont(
            File(
              family == 'PreviewArabic'
                  ? fontPath
                  : const String.fromEnvironment('PREVIEW_LATIN_FONT'),
            ).readAsBytes().then((b) => ByteData.sublistView(b)),
          );
        await loader.load();
      }
      const iconPath = String.fromEnvironment('PREVIEW_ICON_FONT');
      if (iconPath.isNotEmpty) {
        await (FontLoader('MaterialIcons')..addFont(
              File(iconPath).readAsBytes().then((b) => ByteData.sublistView(b)),
            ))
            .load();
      }
    }
  });
  for (final dark in [false, true]) {
    for (final arabic in [false, true]) {
      final mode = '${dark ? 'dark' : 'light'}_${arabic ? 'ar' : 'en'}';
      testWidgets('320px large-text editorial catalog and forms: $mode', (
        tester,
      ) async {
        tester.view.physicalSize =
            const String.fromEnvironment('UI_PREVIEW_DIR').isEmpty
            ? const Size(320, 740)
            : const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        LocaleService().setLanguage(
          arabic ? AppLanguage.arabic : AppLanguage.english,
        );
        final fixture = {
          'id': 'studio-1',
          'name_en': 'Advanced skin barrier serum',
          'name_ar': 'سيروم متخصص لدعم حاجز البشرة',
          'description_en':
              'A considered introduction to a specialist skincare collection.',
          'description_ar':
              'تعرّفي على مجموعة متخصصة للعناية بالبشرة ومكوناتها.',
          'brand_name_en': 'DERMATOLOGY ATELIER',
          'brand_name_ar': 'مختبر العناية الطبية',
          'is_active': true,
        };
        final repo = ProductsRepository(
          apiClient: FakeApiClient(
            onGet: (_, query) => {
              'count': 10000,
              'next': 'page2',
              'results': List.generate(1000, (i) => {...fixture, 'id': '$i'}),
            },
          ),
        );
        Future<void> mount(Widget screen, {double keyboard = 0}) async {
          await tester.pumpWidget(
            MaterialApp(
              theme: const String.fromEnvironment('UI_PREVIEW_DIR').isEmpty
                  ? (dark ? AppTheme.darkTheme : AppTheme.lightTheme)
                  : (dark ? AppTheme.darkTheme : AppTheme.lightTheme).copyWith(
                      textTheme:
                          (dark ? AppTheme.darkTheme : AppTheme.lightTheme)
                              .textTheme
                              .apply(
                                fontFamily: arabic
                                    ? 'PreviewArabic'
                                    : 'PreviewSans',
                              ),
                      appBarTheme:
                          (dark ? AppTheme.darkTheme : AppTheme.lightTheme)
                              .appBarTheme
                              .copyWith(
                                titleTextStyle: TextStyle(
                                  fontFamily: arabic
                                      ? 'PreviewArabic'
                                      : 'PreviewSans',
                                  color: dark
                                      ? AppColors.textPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                    ),
              locale: Locale(arabic ? 'ar' : 'en'),
              supportedLocales: const [Locale('ar'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(
                    const String.fromEnvironment('UI_PREVIEW_DIR').isEmpty
                        ? 1.6
                        : 1.0,
                  ),
                  viewInsets: EdgeInsets.only(bottom: keyboard),
                ),
                child: child!,
              ),
              home: RepaintBoundary(
                key: const ValueKey('preview'),
                child: screen,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        await mount(ProductsScreen(repository: repo));
        expect(
          find.byType(BrandProductMedia).evaluate().length,
          lessThanOrEqualTo(5),
        );
        expect(find.byIcon(Icons.shopping_cart), findsNothing);
        const previewPath = String.fromEnvironment('UI_PREVIEW_DIR');
        if (previewPath.isNotEmpty) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('preview')),
          );
          await tester.runAsync(() async {
            final picture = await boundary.toImage(pixelRatio: 2);
            final bytes = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await Directory(previewPath).create(recursive: true);
            await File(
              '$previewPath/products_$mode.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }
        await mount(
          ProductDetailScreen(product: ProductModel.fromJson(fixture)),
        );
        await mount(const LoginScreen(), keyboard: 260);
        await mount(const RegisterScreen(), keyboard: 260);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
    }
  }
  testWidgets(
    'native button and paged form control wrap Arabic labels with keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    SilverButton(
                      label: 'إرسال طلب الاستشارة إلى العيادة المتخصصة',
                      onPressed: () {},
                      isFullWidth: true,
                    ),
                    PagedEntityField<String>(
                      label: 'الممارس الطبي المفضل',
                      hint: 'ابحث عن الممارس',
                      value: null,
                      valueLabel: '',
                      keyOf: (s) => s,
                      labelOf: (s) => s,
                      loader: (_, _) async => [],
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'embedded thousand-row catalog builds six previews then a lazy View All',
    (tester) async {
      final listenable = ValueNotifier(0);
      var builds = 0;
      final values = List.generate(1000, (i) => '$i');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BoundedCatalogPreview<String>(
                items: () => values,
                listenable: listenable,
                itemBuilder: (_, value) {
                  builds++;
                  return SizedBox(height: 70, child: Text('item $value'));
                },
              ),
            ),
          ),
        ),
      );
      expect(builds, 6);
      await tester.tap(find.byType(TextButton).first);
      await tester.pumpAndSettle();
      expect(builds, lessThan(40));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      listenable.dispose();
    },
  );
  test(
    'shared foreground tokens meet normal-text contrast on both card surfaces',
    () {
      double contrast(Color a, Color b) {
        final x = a.computeLuminance(), y = b.computeLuminance();
        return x > y ? (x + .05) / (y + .05) : (y + .05) / (x + .05);
      }

      for (final color in [
        AppColors.textPrimary,
        AppColors.textSecondary,
        AppColors.textMuted,
        AppColors.silverMuted,
      ]) {
        expect(
          contrast(color, AppColors.cardSurface),
          greaterThanOrEqualTo(4.5),
        );
      }
      for (final color in [
        AppColors.lightTextPrimary,
        AppColors.lightTextSecondary,
        AppColors.lightTextMuted,
      ]) {
        expect(
          contrast(color, AppColors.lightCardSurface),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );
}
