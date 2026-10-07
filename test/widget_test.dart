import 'package:flutter_test/flutter_test.dart';

import 'package:coolify_app/core/api/api_client.dart';
import 'package:coolify_app/core/api/api_exception.dart';
import 'package:coolify_app/core/models/application.dart';
import 'package:coolify_app/core/models/coolify_instance.dart';
import 'package:coolify_app/core/models/deployment.dart';
import 'package:coolify_app/core/models/team.dart';
import 'package:coolify_app/core/utils/json.dart';
import 'package:coolify_app/core/utils/status.dart';

void main() {
  group('json utils', () {
    test('jsonStr coerces primitives', () {
      expect(jsonStr({'a': 'x'}, 'a'), 'x');
      expect(jsonStr({'a': 42}, 'a'), '42');
      expect(jsonStr({'a': null}, 'a'), isNull);
    });

    test('jsonBool handles true/false/1/0 strings', () {
      expect(jsonBool({'a': true}, 'a'), isTrue);
      expect(jsonBool({'a': 1}, 'a'), isTrue);
      expect(jsonBool({'a': '0'}, 'a'), isFalse);
      expect(jsonBool({'a': 'maybe'}, 'a'), isNull);
    });

    test('jsonStrList filters non-strings', () {
      expect(jsonStrList({'a': ['x', 1, null, 'y']}, 'a'), ['x', 'y']);
      expect(jsonStrList({'a': 'nope'}, 'a'), isEmpty);
    });
  });

  group('ResourceStatus', () {
    test('parses running:healthy', () {
      final s = ResourceStatus.parse('running:healthy');
      expect(s.isRunning, isTrue);
      expect(s.isActive, isTrue);
      expect(s.isUnhealthy, isFalse);
      expect(s.label, 'running:healthy');
    });

    test('parses exited:unhealthy', () {
      final s = ResourceStatus.parse('exited:unhealthy');
      expect(s.isExited, isTrue);
      expect(s.isActive, isFalse);
    });

    test('parses building and cancelled', () {
      expect(ResourceStatus.parse('building').isDeploying, isTrue);
      expect(ResourceStatus.parse('queued').isDeploying, isTrue);
      expect(ResourceStatus.parse('cancelled').isCanceled, isTrue);
      expect(ResourceStatus.parse(null).base, 'unknown');
    });
  });

  group('model parsing', () {
    test('Team.fromJson tolerant of missing fields', () {
      final t = Team.fromJson({'id': 1, 'name': 'acme'});
      expect(t.id, 1);
      expect(t.name, 'acme');
      expect(t.description, isNull);
    });

    test('Application.fromJson ignores unknown keys', () {
      final a = Application.fromJson({
        'uuid': 'abc',
        'name': 'store',
        'status': 'running:healthy',
        'some_future_key': {'nested': true},
      });
      expect(a.uuid, 'abc');
      expect(a.name, 'store');
      expect(a.parsedStatus.isRunning, isTrue);
    });

    test('Deployment.fromJson parses status and ids', () {
      final d = Deployment.fromJson({
        'uuid': 'dep-1',
        'application_id': 7,
        'application_name': 'store',
        'status': 'in_progress',
        'commit': 'abc123',
        'created_at': '2026-10-07T10:00:00Z',
      });
      expect(d.deploymentUuid, 'dep-1');
      expect(d.applicationId, 7);
      expect(d.applicationName, 'store');
      expect(d.parsedStatus.isDeploying, isTrue);
      expect(d.commit, 'abc123');
    });
  });

  group('CoolifyInstance', () {
    test('baseUrl appends /api/v1 and trims trailing slashes', () {
      const i = CoolifyInstance(
        id: 'a',
        name: 'local',
        url: 'http://coolify.local:8000/',
        token: 't',
      );
      expect(i.baseUrl, 'http://coolify.local:8000/api/v1');
      expect(i.host, 'coolify.local:8000');
    });
  });

  group('ApiClient', () {
    test('unauthenticated client rejects requests', () async {
      final client = ApiClient.unauthenticated();
      await expectLater(
        client.get('/version'),
        throwsA(isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.unauthenticated)),
      );
    });

    test('fromStatus maps common HTTP codes', () {
      expect(
        ApiException.fromStatus(401, '').kind,
        ApiErrorKind.unauthenticated,
      );
      expect(ApiException.fromStatus(403, '').kind, ApiErrorKind.forbidden);
      expect(ApiException.fromStatus(429, '').kind, ApiErrorKind.rateLimited);
      expect(ApiException.fromStatus(500, '').kind, ApiErrorKind.server);
      expect(ApiException.fromStatus(404, '').kind, ApiErrorKind.notFound);
    });

    test('fromStatus extracts message from JSON body', () {
      final ex = ApiException.fromStatus(401, '{"message":"nope"}');
      expect(ex.message, 'nope');
    });

    test('fromStatus falls back to friendly text', () {
      final ex = ApiException.fromStatus(429, '');
      expect(ex.message, contains('Rate limit'));
    });
  });
}