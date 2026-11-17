import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:brillantea/dominio/accesibilidad_service.dart';
import 'package:brillantea/main.dart';

void main() {
  testWidgets('Accesibilidad textScaler changes when setTamanoTextoIndex is called', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final acc = AccesibilidadService();
    await acc.init();

    await tester.pumpWidget(const SpikeApp());
    await tester.pump();

    // Check initial factor
    expect(acc.factorEscala, 1.0);

    // Change to Grande
    await acc.setTamanoTextoIndex(2);
    await tester.pump();

    expect(acc.factorEscala, 1.30);
  });
}
