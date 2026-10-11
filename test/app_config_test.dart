import 'package:coolify_app/core/models/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.splitDomains', () {
    test('splits on newlines and commas, trimming blanks', () {
      expect(
        AppConfig.splitDomains('https://a.example.com\n\n  https://b.example.com  '),
        ['https://a.example.com', 'https://b.example.com'],
      );
      expect(
        AppConfig.splitDomains('a.com, b.com'),
        ['a.com', 'b.com'],
      );
      expect(AppConfig.splitDomains('   '), isEmpty);
    });
  });

  group('AppConfig.fromApplicationJson', () {
    test('falls back to fqdn when domains is absent', () {
      final c = AppConfig.fromApplicationJson({
        'name': 'demo',
        'fqdn': 'https://demo.example.com',
      });
      expect(c.domains, 'https://demo.example.com');
      expect(c.name, 'demo');
    });

    test('prefers domains over fqdn and reads dockerfile_location', () {
      final c = AppConfig.fromApplicationJson({
        'domains': 'https://a.com\nhttps://b.com',
        'fqdn': 'https://a.com',
        'dockerfile_location': '/Dockerfile',
        'build_pack': 'dockerfile',
        'ports_exposes': '3000',
      });
      expect(c.domains, 'https://a.com\nhttps://b.com');
      expect(c.dockerfile, '/Dockerfile');
      expect(c.buildPack, 'dockerfile');
      expect(c.portsExposes, '3000');
    });

    test('joins docker_compose_domains list into newline text', () {
      final c = AppConfig.fromApplicationJson({
        'docker_compose_domains': ['https://x.com', 'https://y.com'],
      });
      expect(c.dockerComposeDomains, 'https://x.com\nhttps://y.com');
    });
  });

  group('AppConfig.toPatchBody', () {
    test('omits blank strings and nulls', () {
      final body = const AppConfig(name: 'x', description: '  ').toPatchBody();
      expect(body['name'], 'x');
      expect(body.containsKey('description'), isFalse);
    });

    test('converts compose domains textarea into an array', () {
      final body = const AppConfig(
        dockerComposeDomains: 'https://a.com\nhttps://b.com',
      ).toPatchBody();
      expect(body['docker_compose_domains'], ['https://a.com', 'https://b.com']);
    });

    test('is empty when nothing is set', () {
      expect(const AppConfig().toPatchBody(), isEmpty);
    });
  });

  group('ServiceConfig', () {
    test('builds a patch body from compose + metadata', () {
      final body = const ServiceConfig(
        name: 'metube',
        dockerComposeRaw: 'services:\n  app: {}',
        connectToDockerNetwork: true,
      ).toPatchBody();
      expect(body['name'], 'metube');
      expect(body['docker_compose_raw'], 'services:\n  app: {}');
      expect(body['connect_to_docker_network'], isTrue);
    });

    test('is empty for an untouched config', () {
      expect(ServiceConfig.empty.toPatchBody(), isEmpty);
    });
  });
}