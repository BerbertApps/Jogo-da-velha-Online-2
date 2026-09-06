import 'package:flutter_test/flutter_test.dart';

import 'package:jogodavelha/i18n/strings.dart';

void main() {
  test('app title is translated', () {
    L.lang = 'pt';
    expect(L.t('appTitle'), isNotEmpty);
  });
}