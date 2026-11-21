import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dominio/auth_service.dart';
import 'perfil_nino_page.dart';

/// Perfil del responsable en el registro (US902; Figma «Perfil del responsable» y sus estados
/// Parentesco, Ciudad, Completo, Campos faltantes y Formato no válido).
/// Nombre y apellido admiten una sola palabra sin espacios ni tildes; la ciudad y el parentesco se
/// eligen en una hoja inferior. El botón se ve gris hasta que todo está completo; si se toca antes,
/// marca en rojo lo que falta.
class PerfilResponsablePage extends StatefulWidget {
  const PerfilResponsablePage({super.key});

  /// Ciudades o distritos de la hoja «Ciudad» del Figma. También son la respuesta 3 de la recuperación
  /// del PIN («¿En qué ciudad vives?»).
  static const List<String> ciudades = [
    'Barranco',
    'Cercado de Lima',
    'Jesús María',
    'La Molina',
    'Lince',
    'Miraflores',
    'San Borja',
    'San Isidro',
  ];

  /// Opciones de la hoja «Parentesco con el niño o niña» del Figma.
  static const List<String> parentescos = [
    'Mamá',
    'Papá',
    'Abuela o abuelo',
    'Tía o tío',
    'Niñero o niñera',
    'Tutor o tutora legal',
    'Especialista/profesor',
    'Otro',
  ];

  @override
  State<PerfilResponsablePage> createState() => _PerfilResponsablePageState();
}

class _PerfilResponsablePageState extends State<PerfilResponsablePage> {
  static const String _fuente = 'Atkinson Hyperlegible Next';
  static const Color _borde = Color(0xFFDDD6C9);
  static const Color _input = Color(0xFFF6F6F4);
  static const Color _texto = Color(0xFF3A3A3A);
  static const Color _textoSecundario = Color(0xFF6B6B66);
  static const Color _pista = Color(0xFF9A968C);
  static const Color _teal = Color(0xFF3D6D7E);
  static const Color _tealClaro = Color(0xFFDDE9EC);
  static const Color _botonDeshabilitado = Color(0xFFC9D5DA);
  static const Color _error = Color(0xFFB3453A);
  static const Color _bordeError = Color(0xFFB3453A);

  static const List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Setiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  /// Una sola palabra: letras sin tildes (se admite la ñ), sin espacios.
  static final RegExp _unaPalabra = RegExp(r'^[a-zA-ZñÑ]+$');

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _apellidoCtrl = TextEditingController();
  final TextEditingController _diaCtrl = TextEditingController();
  final TextEditingController _anioCtrl = TextEditingController();

  final FocusNode _nombreFocus = FocusNode();
  final FocusNode _apellidoFocus = FocusNode();
  final FocusNode _diaFocus = FocusNode();
  final FocusNode _anioFocus = FocusNode();

  final Set<String> _tocados = {};
  bool _intentoContinuar = false;

  String? _mes;
  String? _ciudad;
  String _sexo = 'Femenino';
  String? _parentesco;

  @override
  void initState() {
    super.initState();
    _nombreFocus.addListener(() => _alSalir(_nombreFocus, 'nombre'));
    _apellidoFocus.addListener(() => _alSalir(_apellidoFocus, 'apellido'));
    _diaFocus.addListener(() => _alSalir(_diaFocus, 'fecha'));
    _anioFocus.addListener(() => _alSalir(_anioFocus, 'fecha'));
  }

  void _alSalir(FocusNode foco, String campo) {
    if (!foco.hasFocus && mounted) setState(() => _tocados.add(campo));
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _diaCtrl.dispose();
    _anioCtrl.dispose();
    _nombreFocus.dispose();
    _apellidoFocus.dispose();
    _diaFocus.dispose();
    _anioFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- validación

  String? _errorNombre() {
    final v = _nombreCtrl.text.trim();
    if (v.isEmpty) return 'Falta escribir tu nombre.';
    if (!_unaPalabra.hasMatch(v) || v.length < 2) return 'Solo un nombre, sin espacios ni tildes.';
    return null;
  }

  String? _errorApellido() {
    final v = _apellidoCtrl.text.trim();
    if (v.isEmpty) return 'Falta escribir tu apellido.';
    if (!_unaPalabra.hasMatch(v) || v.length < 2) return 'Solo tu primer apellido, sin espacios ni tildes.';
    return null;
  }

  String? _errorFecha() {
    final dia = int.tryParse(_diaCtrl.text.trim());
    final anio = int.tryParse(_anioCtrl.text.trim());
    if (dia == null || _mes == null || anio == null || _anioCtrl.text.trim().length != 4) {
      return 'Completa tu fecha de nacimiento.';
    }
    final mes = _meses.indexOf(_mes!) + 1;
    final fecha = DateTime(anio, mes, dia);
    if (dia < 1 || fecha.month != mes || anio < 1920) return 'Revisa tu fecha de nacimiento.';
    final hoy = DateTime.now();
    final mayorDeEdad = DateTime(hoy.year - 18, hoy.month, hoy.day);
    if (fecha.isAfter(mayorDeEdad)) return 'Debes ser mayor de edad.';
    return null;
  }

  String? _errorCiudad() => _ciudad == null ? 'Elige tu ciudad.' : null;
  String? _errorParentesco() => _parentesco == null ? 'Elige tu parentesco.' : null;

  bool get _completo =>
      _errorNombre() == null &&
      _errorApellido() == null &&
      _errorFecha() == null &&
      _errorCiudad() == null &&
      _errorParentesco() == null;

  /// El error de un campo se muestra después de salir de él o al tocar Continuar.
  String? _visible(String campo, String? error) =>
      (_intentoContinuar || _tocados.contains(campo)) ? error : null;

  void _continuar() {
    FocusScope.of(context).unfocus();
    if (!_completo) {
      setState(() => _intentoContinuar = true);
      return;
    }
    final anio = _anioCtrl.text.trim();
    final adulto = PerfilAdulto(
      nombres: _nombreCtrl.text.trim(),
      apellidoPaterno: _apellidoCtrl.text.trim(),
      apellidoMaterno: '',
      diaNacimiento: int.parse(_diaCtrl.text.trim()).toString(),
      mesNacimiento: _mes!,
      anioNacimiento: anio,
      ciudadNacimiento: _ciudad!,
      edad: '${DateTime.now().year - int.parse(anio)}',
      sexo: _sexo,
      parentesco: _parentesco!,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PerfilNinoPage(perfilAdulto: adulto)),
    );
  }

  // ---------------------------------------------------------------- hojas de selección

  Future<void> _elegir({
    required String titulo,
    required List<String> opciones,
    required String? actual,
    required ValueChanged<String> alElegir,
  }) async {
    FocusScope.of(context).unfocus();
    final elegido = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: const Color(0x733A3A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: _borde, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 13, 24, 12),
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontFamily: _fuente,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _texto,
                  ),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  children: [
                    for (final o in opciones) _opcionHoja(ctx, o, o == actual),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (elegido != null && mounted) setState(() => alElegir(elegido));
  }

  Widget _opcionHoja(BuildContext ctx, String opcion, bool marcada) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        selected: marcada,
        button: true,
        child: Material(
          color: marcada ? _tealClaro : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(ctx).pop(opcion),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: marcada ? _teal : Colors.white,
                      border: Border.all(color: marcada ? _teal : _borde, width: 2),
                    ),
                    child: marcada ? const Icon(Icons.check_rounded, size: 14, color: Colors.white) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opcion,
                      style: TextStyle(
                        fontFamily: _fuente,
                        fontSize: 16,
                        fontWeight: marcada ? FontWeight.w700 : FontWeight.w400,
                        color: _texto,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- pantalla

  @override
  Widget build(BuildContext context) {
    final tecladoAbierto = MediaQuery.of(context).viewInsets.bottom > 0;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _encabezado(),
                      const SizedBox(height: 20),
                      const Text(
                        'Cuéntanos quién acompañará al niño o niña en la app.',
                        style: TextStyle(
                          fontFamily: _fuente,
                          fontSize: 18,
                          height: 1.5,
                          color: _textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _etiqueta('Nombre'),
                      _campoTexto(
                        ctrl: _nombreCtrl,
                        foco: _nombreFocus,
                        pista: 'Ej. Maria',
                        error: _visible('nombre', _errorNombre()),
                        siguiente: _apellidoFocus,
                      ),
                      _etiqueta('Apellido'),
                      _campoTexto(
                        ctrl: _apellidoCtrl,
                        foco: _apellidoFocus,
                        pista: 'Ej. Gomez',
                        error: _visible('apellido', _errorApellido()),
                        siguiente: _diaFocus,
                      ),
                      _etiqueta('Fecha de nacimiento'),
                      _campoFecha(),
                      _etiqueta('Ciudad'),
                      _selector(
                        valor: _ciudad,
                        error: _visible('ciudad', _errorCiudad()),
                        onTap: () => _elegir(
                          titulo: 'Ciudad',
                          opciones: PerfilResponsablePage.ciudades,
                          actual: _ciudad,
                          alElegir: (v) => _ciudad = v,
                        ).then((_) => _marcar('ciudad')),
                      ),
                      _etiqueta('Sexo'),
                      _chipsSexo(),
                      _etiqueta('Parentesco con el niño o niña'),
                      _selector(
                        valor: _parentesco,
                        error: _visible('parentesco', _errorParentesco()),
                        onTap: () => _elegir(
                          titulo: 'Parentesco con el niño o niña',
                          opciones: PerfilResponsablePage.parentescos,
                          actual: _parentesco,
                          alElegir: (v) => _parentesco = v,
                        ).then((_) => _marcar('parentesco')),
                      ),
                    ],
                  ),
                ),
              ),
              if (!tecladoAbierto)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: _botonContinuar(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _marcar(String campo) {
    if (mounted) setState(() => _tocados.add(campo));
  }

  Widget _encabezado() {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Volver',
          excludeSemantics: true,
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: _borde, width: 1.5),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _texto, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Perfil del responsable',
            style: TextStyle(
              fontFamily: _fuente,
              fontSize: 24,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: _texto,
            ),
          ),
        ),
      ],
    );
  }

  Widget _etiqueta(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        texto,
        style: const TextStyle(fontFamily: _fuente, fontSize: 14, height: 1.4, color: _textoSecundario),
      ),
    );
  }

  BoxDecoration _caja({required bool error, bool activo = false}) {
    return BoxDecoration(
      color: _input,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: error ? _bordeError : (activo ? _teal : _borde),
        width: error || activo ? 2 : 1.5,
      ),
    );
  }

  Widget _mensajeError(String? error) {
    if (error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 15, color: _error),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontFamily: _fuente,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoTexto({
    required TextEditingController ctrl,
    required FocusNode foco,
    required String pista,
    required String? error,
    required FocusNode siguiente,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: foco,
          builder: (_, child) => Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: _caja(error: error != null, activo: foco.hasFocus),
            child: child,
          ),
          child: TextField(
            controller: ctrl,
            focusNode: foco,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => siguiente.requestFocus(),
            style: const TextStyle(fontFamily: _fuente, fontSize: 18, color: _texto),
            decoration: InputDecoration(
              isCollapsed: true,
              hintText: pista,
              hintStyle: const TextStyle(fontFamily: _fuente, fontSize: 18, color: _pista),
              border: InputBorder.none,
            ),
          ),
        ),
        _mensajeError(error),
      ],
    );
  }

  Widget _campoFecha() {
    final error = _visible('fecha', _errorFecha());
    Widget numero(TextEditingController c, FocusNode f, String pista, int largo, double ancho,
        FocusNode? siguiente) {
      return SizedBox(
        width: ancho,
        child: AnimatedBuilder(
          animation: f,
          builder: (_, child) => Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: _caja(error: error != null, activo: f.hasFocus),
            child: child,
          ),
          child: TextField(
            controller: c,
            focusNode: f,
            keyboardType: TextInputType.number,
            textInputAction: siguiente == null ? TextInputAction.done : TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(largo),
            ],
            onChanged: (v) {
              setState(() {});
              if (v.length == largo && siguiente != null) siguiente.requestFocus();
            },
            style: const TextStyle(fontFamily: _fuente, fontSize: 18, color: _texto),
            decoration: InputDecoration(
              isCollapsed: true,
              hintText: pista,
              hintStyle: const TextStyle(fontFamily: _fuente, fontSize: 18, color: _pista),
              border: InputBorder.none,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            numero(_diaCtrl, _diaFocus, 'DD', 2, 84, null),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Mes de nacimiento${_mes == null ? '' : ', $_mes'}',
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _elegir(
                    titulo: 'Mes de nacimiento',
                    opciones: _meses,
                    actual: _mes,
                    alElegir: (v) => _mes = v,
                  ).then((_) => _marcar('fecha')),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.only(left: 16, right: 10),
                    decoration: _caja(error: error != null),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _mes ?? 'Mes',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: _fuente,
                              fontSize: 18,
                              color: _mes == null ? _pista : _texto,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: _texto, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            numero(_anioCtrl, _anioFocus, 'AAAA', 4, 96, null),
          ],
        ),
        _mensajeError(error),
      ],
    );
  }

  Widget _selector({required String? valor, required String? error, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: valor ?? 'Selecciona una opción',
          excludeSemantics: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              height: 48,
              padding: const EdgeInsets.only(left: 16, right: 14),
              decoration: _caja(error: error != null),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      valor ?? 'Selecciona una opción',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: _fuente,
                        fontSize: 18,
                        color: valor == null ? _pista : _texto,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: _texto, size: 22),
                ],
              ),
            ),
          ),
        ),
        _mensajeError(error),
      ],
    );
  }

  Widget _chipsSexo() {
    const opciones = ['Femenino', 'Masculino', 'Otro'];
    return Row(
      children: [
        for (var i = 0; i < opciones.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _chip(opciones[i])),
        ],
      ],
    );
  }

  Widget _chip(String opcion) {
    final marcado = _sexo == opcion;
    return Semantics(
      selected: marcado,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _sexo = opcion),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: marcado ? _tealClaro : _input,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: marcado ? _teal : _borde, width: marcado ? 2 : 1.5),
          ),
          child: Text(
            opcion,
            style: TextStyle(
              fontFamily: _fuente,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: marcado ? _teal : _texto,
            ),
          ),
        ),
      ),
    );
  }

  Widget _botonContinuar() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _continuar,
        style: ElevatedButton.styleFrom(
          backgroundColor: _completo ? _teal : _botonDeshabilitado,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          'Continuar',
          style: TextStyle(fontFamily: _fuente, fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
