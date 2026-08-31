import 'package:flutter_test/flutter_test.dart';
import 'package:paperless_mobile/core/security/system_http_proxy.dart';

void main() {
  tearDown(SystemHttpProxy.clear);

  test('loopback is always DIRECT', () {
    SystemHttpProxy.apply(host: '10.0.0.1', port: 8080);

    expect(
      SystemHttpProxy.findProxy(Uri.parse('https://localhost/api/')),
      'DIRECT',
    );
    expect(
      SystemHttpProxy.findProxy(Uri.parse('http://127.0.0.1:3131/api/')),
      'DIRECT',
    );
    expect(
      SystemHttpProxy.findProxy(
        Uri(scheme: 'https', host: '::1', path: '/api/'),
      ),
      'DIRECT',
    );
  });

  test('configured native proxy is used for remote hosts', () {
    SystemHttpProxy.apply(host: '10.0.0.1', port: 8080);

    expect(
      SystemHttpProxy.findProxy(Uri.parse('https://paperless.example/api/')),
      'PROXY 10.0.0.1:8080',
    );
  });

  test('cleared proxy falls back to environment (DIRECT when unset)', () {
    SystemHttpProxy.apply(host: '10.0.0.1', port: 8080);
    SystemHttpProxy.clear();

    expect(
      SystemHttpProxy.findProxy(Uri.parse('https://paperless.example/api/')),
      'DIRECT',
    );
  });

  test('socketTarget uses proxy host without looking up the request host', () {
    final target = SystemHttpProxy.socketTarget(
      Uri.parse('https://paperless.example/api/'),
      '10.0.0.1',
      8080,
    );

    expect(target.host, '10.0.0.1');
    expect(target.port, 8080);
    expect(target.tlsToTarget, isFalse);
  });

  test('socketTarget DIRECT https uses 443 and TLS to the request host', () {
    final target = SystemHttpProxy.socketTarget(
      Uri.parse('https://paperless.example/api/'),
      null,
      null,
    );

    expect(target.host, 'paperless.example');
    expect(target.port, 443);
    expect(target.tlsToTarget, isTrue);
  });
}
