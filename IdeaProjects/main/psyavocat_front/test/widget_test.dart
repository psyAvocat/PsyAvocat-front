import 'package:flutter_test/flutter_test.dart';
import 'package:psyavocat_front/core/config/app_config.dart';

void main() {
  test('AppConfig smoke test', () {
    expect(AppConfig.appName, equals('PsyAvocat'));
    expect(AppConfig.apiBaseUrl, isNotEmpty);
  });
}
