import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brillantea/presentacion/comun/pin_input_cuadros.dart';

void main() {
  testWidgets('PinInputCuadros muestra 4 casillas y maneja escritura y borrado', (tester) async {
    final controller = TextEditingController();
    String? completedPin;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PinInputCuadros(
              controller: controller,
              onCompleted: (val) => completedPin = val,
            ),
          ),
        ),
      ),
    );

    // Inicialmente vacío
    expect(find.byType(PinInputCuadros), findsOneWidget);
    expect(controller.text, '');

    // Simular escritura interactiva de dígito 1 a través del TextField
    await tester.enterText(find.byType(TextField), '7');
    await tester.pump();
    expect(controller.text, '7');
    expect(find.text('•'), findsNWidgets(1));

    // Simular que el usuario presiona borrar (Backspace) interactivo
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(controller.text, '');
    expect(find.text('•'), findsNothing);

    // Simular ingreso de 4 dígitos
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    expect(find.text('•'), findsNWidgets(4));
    expect(controller.text, '1234');
    expect(completedPin, '1234');
  });
}
