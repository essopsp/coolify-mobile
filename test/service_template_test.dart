import 'dart:io';

import 'package:coolify_app/core/models/service_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServiceTemplate catalog', () {
    test('is populated and sorted', () {
      expect(ServiceTemplate.catalog.length, greaterThan(300));
      final types = ServiceTemplate.catalog.map((e) => e.type).toList();
      expect(types.toSet().length, types.length, reason: 'duplicate types');
      final sorted = [...types]..sort();
      expect(types, sorted);
    });

    test('every logo asset exists on disk', () {
      final missing = <String>[];
      for (final t in ServiceTemplate.catalog) {
        final asset = t.logoAsset;
        if (asset == null) continue;
        if (!File(asset).existsSync()) missing.add('${t.type} -> $asset');
      }
      expect(missing, isEmpty,
          reason: 'catalogue references assets that are not bundled');
    });

    test('most entries have a logo', () {
      final withLogo =
          ServiceTemplate.catalog.where((e) => e.logoAsset != null).length;
      expect(withLogo, greaterThan(ServiceTemplate.catalog.length - 5));
    });

    test('searchKey matches type and slogan case-insensitively', () {
      const t = ServiceTemplate('n8n', 'Workflow Automation', null);
      expect(t.searchKey, contains('n8n'));
      expect(t.searchKey, contains('workflow automation'));
    });
  });
}