import 'package:flutter_test/flutter_test.dart';
import 'package:zonasos_flutter/main.dart';

void main() {
  testWidgets('Carga inicial de MyApp', (WidgetTester tester) async {
    // Renderiza la clase principal de la aplicación
    await tester.pumpWidget(const MyApp());

    // Verifica que el widget principal cargue en pantalla
    expect(find.byType(MyApp), findsOneWidget);
  });
}