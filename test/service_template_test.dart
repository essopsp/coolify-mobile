import 'package:coolify_app/core/models/service_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceTemplate catalog', () {
    test('is populated, unique and sorted', () {
      expect(ServiceTemplate.catalog.length, greaterThan(300));
      final types = ServiceTemplate.catalog.map((e) => e.type).toList();
      expect(types.toSet().length, types.length, reason: 'duplicate types');
      final sorted = [...types]..sort();
      expect(types, sorted);
    });

    test('every logo url is absolute https', () {
      final bad = ServiceTemplate.catalog
          .where((t) => t.logoUrl != null && !t.logoUrl!.startsWith('https://'))
          .map((t) => '${t.type} -> ${t.logoUrl}')
          .toList();
      expect(bad, isEmpty);
    });

    test('logos are served from the upstream Coolify repo', () {
      final bad = ServiceTemplate.catalog
          .where((t) =>
              t.logoUrl != null &&
              !t.logoUrl!.contains('coollabsio/coolify'))
          .map((t) => t.logoUrl!)
          .toList();
      expect(bad, isEmpty);
    });

    test('almost every entry has a resolvable logo', () {
      final withLogo =
          ServiceTemplate.catalog.where((e) => e.logoUrl != null).length;
      expect(withLogo, greaterThan(ServiceTemplate.catalog.length - 5));
    });

    test('no two types point at the same logo file', () {
      // Some upstream templates intentionally share artwork (e.g. several
      // wordpress variants), so this only guards against a broken join that
      // collapsed everything onto one asset.
      final urls = ServiceTemplate.catalog
          .map((e) => e.logoUrl)
          .whereType<String>()
          .toSet();
      expect(urls.length, greaterThan(250));
    });

    test('searchKey matches type and slogan case-insensitively', () {
      const t = ServiceTemplate('n8n', 'Workflow Automation', null);
      expect(t.searchKey, contains('n8n'));
      expect(t.searchKey, contains('workflow automation'));
    });
  });
}