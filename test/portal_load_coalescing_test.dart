import 'package:flutter_test/flutter_test.dart';
import 'package:aesthetic_way/features/admin/data/admin_repository.dart';
import 'package:aesthetic_way/features/admin/services/admin_portal_service.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_leads_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/data/clinic_catalog_repository.dart';
import 'package:aesthetic_way/features/clinic_portal/services/clinic_portal_service.dart';
import 'products_articles_live_test.dart' show FakeApiClient;

void main() {
  test(
    '500 concurrent clinic dashboard loads issue one request per resource, no unrelated catalog preloads',
    () async {
      final counts = <String, int>{};
      final api = FakeApiClient(
        onGet: (path, _) {
          counts[path] = (counts[path] ?? 0) + 1;
          if (path.endsWith('leads/')) {
            return {'count': 0, 'next': null, 'results': []};
          }
          return {'id': 'clinic', 'name_en': 'Clinic', 'name_ar': 'العيادة'};
        },
      );
      final service = ClinicPortalService()..resetTestingState();
      service.setRepositoryForTesting(ClinicLeadsRepository(apiClient: api));
      service.setCatalogRepositoryForTesting(
        ClinicCatalogRepository(apiClient: api),
      );
      await Future.wait(List.generate(500, (_) => service.loadPortalData()));
      expect(counts, isNotEmpty);
      expect(counts.values.every((count) => count == 1), isTrue);
      expect(
        counts.keys.any(
          (key) =>
              key.contains('products') ||
              key.contains('treatments') ||
              key.contains('articles'),
        ),
        isFalse,
      );
      final before = Map.of(counts);
      await service.loadPortalData();
      expect(counts, before);
      service.resetTestingState();
    },
  );
  test(
    '500 concurrent admin loadAllData calls fetch each first page once',
    () async {
      final counts = <String, int>{};
      final api = FakeApiClient(
        onGet: (path, _) {
          counts[path] = (counts[path] ?? 0) + 1;
          return {'count': 0, 'next': null, 'results': []};
        },
      );
      final service = AdminPortalService()..resetTestingState();
      AdminPortalService(repository: AdminRepository(apiClient: api));
      await Future.wait(List.generate(500, (_) => service.loadAllData()));
      expect(counts.length, 7);
      expect(counts.values.every((count) => count == 1), isTrue);
      service.resetTestingState();
    },
  );
}
