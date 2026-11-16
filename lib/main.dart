import 'package:flutter/material.dart';

import 'dominio/accesibilidad_service.dart';
import 'dominio/reporte_service.dart';
import 'presentacion/registro/bienvenida_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // RNF-04: borra las copias temporales del reporte PDF que quedaron de exportaciones anteriores.
  ReporteService.limpiarViejos();
  await AccesibilidadService().init();
  runApp(const SpikeApp());
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const tealClinico = Color(0xFF3D6D7E);

    return ListenableBuilder(
      listenable: AccesibilidadService(),
      builder: (context, _) {
        final factor = AccesibilidadService().factorEscala;

        return MaterialApp(
          title: 'BrillanTEA',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: tealClinico,
            useMaterial3: true,
            scaffoldBackgroundColor: Colors.white,
          ),
          builder: (context, child) {
            final mediaQuery = MediaQuery.maybeOf(context) ??
                MediaQueryData.fromView(View.of(context));
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(factor),
              ),
              child: child!,
            );
          },
          home: const BienvenidaPage(),
        );
      },
    );
  }
}
