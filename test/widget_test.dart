// TR: Bu basit bir Flutter widget testidir | EN: This is a basic Flutter widget test | RU: Это базовый тест виджета Flutter
// TR: Widget etkileşimleri için WidgetTester kullanılır; dokunma ve kaydırma gibi jestleri simüle edip widget ağacındaki değerleri doğrulayabilirsiniz | EN: Use WidgetTester for widget interactions; simulate taps/scrolls and validate values in the widget tree | RU: Для взаимодействий с виджетами используйте WidgetTester; можно эмулировать нажатия/прокрутки и проверять значения в дереве виджетов

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:design/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // TR: Uygulamayı oluştur ve ilk frame'i tetikle | EN: Build the app and trigger the first frame | RU: Собери приложение и запусти первый кадр
    await tester.pumpWidget(const Root());

    // TR: Sayacın 0’dan başladığını doğrula | EN: Verify the counter starts at 0 | RU: Убедись, что счётчик начинается с 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // TR: '+' ikonuna dokun ve yeni frame'i tetikle | EN: Tap the '+' icon and trigger a new frame | RU: Нажми на иконку '+' и запусти новый кадр
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // TR: Sayacın arttığını doğrula | EN: Verify the counter incremented | RU: Убедись, что счётчик увеличился
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
