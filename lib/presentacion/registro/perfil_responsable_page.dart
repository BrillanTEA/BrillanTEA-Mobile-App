import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../dominio/auth_service.dart';
import '../comun/formatters.dart';
import 'perfil_nino_page.dart';

/// Perfil del responsable en el registro.
/// Nombres, apellidos y ciudad solo admiten letras sin tildes y un espacio entre palabras; los espacios
/// sobrantes se quitan al salir del campo. Con el teclado abierto se oculta el botón inferior para que
/// no tape los campos.
class PerfilResponsablePage extends StatefulWidget {
  const PerfilResponsablePage({super.key});

  @override
  State<PerfilResponsablePage> createState() => _PerfilResponsablePageState();
}

class _PerfilResponsablePageState extends State<PerfilResponsablePage> {
  static const Color colorFondo = Color(0xFFFFFFFF);
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorInput = Color(0xFFF6F6F4);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTextoSecundario = Color(0xFF6B6B66);
  static const Color colorPista = Color(0xFF9A968C);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorBotonDeshabilitado = Color(0xFFC9D5DA);
  static const Color colorError = Color(0xFFD32F2F);

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _apellidoPaternoCtrl = TextEditingController();
  final TextEditingController _apellidoMaternoCtrl = TextEditingController();
  final TextEditingController _diaCtrl = TextEditingController();
  final TextEditingController _anioCtrl = TextEditingController();
  final TextEditingController _ciudadCtrl = TextEditingController();

  // Al salir de un campo se quitan los espacios sobrantes
  final FocusNode _nombreFocus = FocusNode();
  final FocusNode _apellidoPaternoFocus = FocusNode();
  final FocusNode _apellidoMaternoFocus = FocusNode();
  final FocusNode _diaFocus = FocusNode();
  final FocusNode _anioFocus = FocusNode();
  final FocusNode _ciudadFocus = FocusNode();

  final ScrollController _scrollController = ScrollController();
  final Set<String> _camposTocados = {};

  String? _mesSeleccionado;
  String _sexoSeleccionado = 'Femenino';
  String? _parentescoSeleccionado;

  final List<String> _meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Setiembre', 'Octubre', 'Noviembre', 'Diciembre'
  ];

  final List<String> _parentescos = [
    'Madre', 'Padre', 'Tutor legal', 'Terapeuta', 'Docente', 'Familiar'
  ];

  bool _haIntentadoContinuar = false;

  // Regex estricto para nombres: Solo letras sin tildes, ñ, un espacio entre palabras
  static final RegExp _regexLetrasValidas = RegExp(r"^[a-zA-ZñÑ]+(?:\s[a-zA-ZñÑ]+)*$");

  @override
  void initState() {
    super.initState();
    // Auto-trim automático al perder el foco en cualquier campo de texto y registro de touch
    _nombreFocus.addListener(() => _alPerderFoco(_nombreCtrl, _nombreFocus, 'nombre'));
    _apellidoPaternoFocus.addListener(() => _alPerderFoco(_apellidoPaternoCtrl, _apellidoPaternoFocus, 'paterno'));
    _apellidoMaternoFocus.addListener(() => _alPerderFoco(_apellidoMaternoCtrl, _apellidoMaternoFocus, 'materno'));
    _ciudadFocus.addListener(() => _alPerderFoco(_ciudadCtrl, _ciudadFocus, 'ciudad'));
    _diaFocus.addListener(() => _alPerderFoco(_diaCtrl, _diaFocus, 'dia'));
    _anioFocus.addListener(() => _alPerderFoco(_anioCtrl, _anioFocus, 'anio'));
  }

  void _alPerderFoco(TextEditingController ctrl, FocusNode focus, String campoId) {
    if (!focus.hasFocus) {
      _camposTocados.add(campoId);
      final textoLimpio = limpiarTildes(ctrl.text.trim().replaceAll(RegExp(r'\s+'), ' '));
      if (ctrl.text != textoLimpio) {
        ctrl.value = TextEditingValue(
          text: textoLimpio,
          selection: TextSelection.collapsed(offset: textoLimpio.length),
        );
      }
      setState(() {});
    }
  }

  void _asegurarSinTildes(TextEditingController ctrl) {
    final limpio = limpiarTildes(ctrl.text);
    if (ctrl.text != limpio) {
      final diff = ctrl.text.length - limpio.length;
      final newOffset = (ctrl.selection.end - diff).clamp(0, limpio.length);
      ctrl.value = TextEditingValue(
        text: limpio,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
    setState(() {});
  }

  void _avanzarAlSiguienteCampo() {
    if (_nombreFocus.hasFocus) {
      _enfocarYDesplazar(_apellidoPaternoFocus);
    } else if (_apellidoPaternoFocus.hasFocus) {
      _enfocarYDesplazar(_apellidoMaternoFocus);
    } else if (_apellidoMaternoFocus.hasFocus) {
      _enfocarYDesplazar(_diaFocus);
    } else if (_diaFocus.hasFocus) {
      _enfocarYDesplazar(_anioFocus);
    } else if (_anioFocus.hasFocus) {
      _enfocarYDesplazar(_ciudadFocus);
    } else if (_ciudadFocus.hasFocus) {
      FocusScope.of(context).unfocus();
    } else {
      _enfocarYDesplazar(_nombreFocus);
    }
  }

  void _enfocarYDesplazar(FocusNode siguiente) {
    siguiente.requestFocus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nombreCtrl.dispose();
    _apellidoPaternoCtrl.dispose();
    _apellidoMaternoCtrl.dispose();
    _diaCtrl.dispose();
    _anioCtrl.dispose();
    _ciudadCtrl.dispose();

    _nombreFocus.dispose();
    _apellidoPaternoFocus.dispose();
    _apellidoMaternoFocus.dispose();
    _diaFocus.dispose();
    _anioFocus.dispose();
    _ciudadFocus.dispose();

    super.dispose();
  }

  String? _validarNombre(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa el nombre';
    }
    final limpio = valor.trim();
    if (limpio.length < 2) {
      return 'Mínimo 2 caracteres';
    }
    if (!_regexLetrasValidas.hasMatch(limpio)) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  String? _validarApellido(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa el $campo';
    }
    final limpio = valor.trim();
    if (limpio.length < 2) {
      return 'Mínimo 2 caracteres';
    }
    if (!_regexLetrasValidas.hasMatch(limpio)) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  String? _validarDia(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Día requerido';
    final d = int.tryParse(valor.trim());
    if (d == null || d < 1 || d > 31) return 'Día inválido (1-31)';
    return null;
  }

  String? _validarAnio(String? valor) {
    if (valor == null || valor.trim().isEmpty) return 'Año requerido';
    final limpio = valor.trim();
    if (limpio.length < 4) return 'Ingresa 4 dígitos (Ej. 1988)';
    final a = int.tryParse(limpio);
    if (a == null) return 'Año inválido (solo números)';
    final anioActual = DateTime.now().year;
    if (a < 1920) return 'Año muy antiguo';
    if (a > anioActual - 18) return 'Debe ser mayor de edad (+18)';
    return null;
  }

  String? _validarCiudad(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa la ciudad de nacimiento';
    }
    final limpio = valor.trim();
    if (limpio.length < 2) {
      return 'Mínimo 2 caracteres';
    }
    if (!_regexLetrasValidas.hasMatch(limpio)) {
      return 'Solo se permiten letras';
    }
    return null;
  }

  bool get _formularioValido =>
      _validarNombre(_nombreCtrl.text) == null &&
      _validarApellido(_apellidoPaternoCtrl.text, 'apellido paterno') == null &&
      _validarApellido(_apellidoMaternoCtrl.text, 'apellido materno') == null &&
      _validarDia(_diaCtrl.text) == null &&
      _mesSeleccionado != null &&
      _validarAnio(_anioCtrl.text) == null &&
      _validarCiudad(_ciudadCtrl.text) == null &&
      _parentescoSeleccionado != null;

  void _continuar() {
    FocusScope.of(context).unfocus();
    setState(() => _haIntentadoContinuar = true);

    if (!_formularioValido) {
      String primerError = '';
      double scrollTarget = 0.0;

      if (_validarNombre(_nombreCtrl.text) != null) {
        primerError = 'Nombre: ${_validarNombre(_nombreCtrl.text)}';
        scrollTarget = 0.0;
      } else if (_validarApellido(_apellidoPaternoCtrl.text, 'apellido paterno') != null) {
        primerError = 'Apellido paterno: ${_validarApellido(_apellidoPaternoCtrl.text, 'apellido paterno')}';
        scrollTarget = 60.0;
      } else if (_validarApellido(_apellidoMaternoCtrl.text, 'apellido materno') != null) {
        primerError = 'Apellido materno: ${_validarApellido(_apellidoMaternoCtrl.text, 'apellido materno')}';
        scrollTarget = 140.0;
      } else if (_validarDia(_diaCtrl.text) != null) {
        primerError = 'Fecha: ${_validarDia(_diaCtrl.text)}';
        scrollTarget = 220.0;
      } else if (_mesSeleccionado == null) {
        primerError = 'Fecha: Selecciona el mes de nacimiento';
        scrollTarget = 220.0;
      } else if (_validarAnio(_anioCtrl.text) != null) {
        primerError = 'Fecha: ${_validarAnio(_anioCtrl.text)}';
        scrollTarget = 220.0;
      } else if (_validarCiudad(_ciudadCtrl.text) != null) {
        primerError = 'Ciudad: ${_validarCiudad(_ciudadCtrl.text)}';
        scrollTarget = 300.0;
      } else if (_parentescoSeleccionado == null) {
        primerError = 'Parentesco: Selecciona una opción';
        scrollTarget = 400.0;
      }

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          scrollTarget,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            primerError.isNotEmpty ? primerError : 'Por favor completa los campos requeridos marcados en rojo.',
            style: const TextStyle(fontFamily: 'Atkinson Hyperlegible Next', fontWeight: FontWeight.w600),
          ),
          backgroundColor: colorError,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Limpieza final de espacios antes de guardar en Base de Datos
    final nombreLimpio = _nombreCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final paternoLimpio = _apellidoPaternoCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final maternoLimpio = _apellidoMaternoCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final ciudadLimpia = _ciudadCtrl.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final diaLimpio = _diaCtrl.text.trim();
    final anioLimpio = _anioCtrl.text.trim();

    // Edad calculada automáticamente a partir del año de nacimiento
    final anioInt = int.tryParse(anioLimpio) ?? DateTime.now().year;
    final edadCalculada = '${DateTime.now().year - anioInt}';

    final adulto = PerfilAdulto(
      nombres: nombreLimpio,
      apellidoPaterno: paternoLimpio,
      apellidoMaterno: maternoLimpio,
      diaNacimiento: diaLimpio,
      mesNacimiento: _mesSeleccionado!,
      anioNacimiento: anioLimpio,
      ciudadNacimiento: ciudadLimpia,
      edad: edadCalculada,
      sexo: _sexoSeleccionado,
      parentesco: _parentescoSeleccionado!,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PerfilNinoPage(perfilAdulto: adulto),
      ),
    );
  }

  void _abrirSelectorMes() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorBorde,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mes de nacimiento',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorTextoPrincipal,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.48,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _meses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2F2EE)),
                    itemBuilder: (ctx, i) {
                      final m = _meses[i];
                      final sel = _mesSeleccionado == m;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        title: Text(
                          m,
                          style: TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 16,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? colorTealPrimario : colorTextoPrincipal,
                          ),
                        ),
                        trailing: sel
                            ? const Icon(Icons.check_circle_rounded, color: colorTealPrimario, size: 24)
                            : null,
                        onTap: () {
                          setState(() => _mesSeleccionado = m);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _abrirSelectorParentesco() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorBorde,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Parentesco con el niño o niña',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorTextoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Selecciona la relación del acompañante principal',
                  style: TextStyle(
                    fontFamily: 'Atkinson Hyperlegible Next',
                    fontSize: 14,
                    color: colorTextoSecundario,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _parentescos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2F2EE)),
                  itemBuilder: (ctx, i) {
                    final p = _parentescos[i];
                    final sel = _parentescoSeleccionado == p;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      title: Text(
                        p,
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 16,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? colorTealPrimario : colorTextoPrincipal,
                        ),
                      ),
                      trailing: sel
                          ? const Icon(Icons.check_circle_rounded, color: colorTealPrimario, size: 24)
                          : null,
                      onTap: () {
                        setState(() => _parentescoSeleccionado = p);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formValido = _formularioValido;
    final tecladoVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    // Errores para visualización (feedback inmediato por campo tocado o tras presionar continuar)
    final errorNombre = (_haIntentadoContinuar || _camposTocados.contains('nombre'))
        ? _validarNombre(_nombreCtrl.text)
        : null;
    final errorPaterno = (_haIntentadoContinuar || _camposTocados.contains('paterno'))
        ? _validarApellido(_apellidoPaternoCtrl.text, 'apellido paterno')
        : null;
    final errorMaterno = (_haIntentadoContinuar || _camposTocados.contains('materno'))
        ? _validarApellido(_apellidoMaternoCtrl.text, 'apellido materno')
        : null;
    final errorDia = (_haIntentadoContinuar || _camposTocados.contains('dia'))
        ? _validarDia(_diaCtrl.text)
        : null;
    final errorMes = (_haIntentadoContinuar || _camposTocados.contains('mes')) && _mesSeleccionado == null
        ? 'Selecciona el mes'
        : null;
    final errorAnio = (_haIntentadoContinuar || _camposTocados.contains('anio'))
        ? _validarAnio(_anioCtrl.text)
        : null;
    final errorCiudad = (_haIntentadoContinuar || _camposTocados.contains('ciudad'))
        ? _validarCiudad(_ciudadCtrl.text)
        : null;
    final errorParentesco = (_haIntentadoContinuar || _camposTocados.contains('parentesco')) && _parentescoSeleccionado == null
        ? 'Selecciona una opción'
        : null;

    return GestureDetector(
      // Tocar cualquier parte fuera de los inputs cierra el teclado inmediatamente
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: colorFondo,
        bottomNavigationBar: tecladoVisible
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        offset: const Offset(0, -2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => FocusScope.of(context).unfocus(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: colorTextoPrincipal),
                          label: const Text(
                            'Bajar teclado ⌄',
                            style: TextStyle(
                              fontFamily: 'Atkinson Hyperlegible Next',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colorTextoPrincipal,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: colorBorde, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _avanzarAlSiguienteCampo,
                          icon: const Icon(Icons.arrow_downward_rounded, size: 18, color: Colors.white),
                          label: const Text(
                            'Siguiente campo ↓',
                            style: TextStyle(
                              fontFamily: 'Atkinson Hyperlegible Next',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorTealPrimario,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom + 8
                      : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      offset: const Offset(0, -3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: _buildBotonContinuar(formValido),
              ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: Row(
                  children: [
                    Semantics(button: true, label: 'Volver', child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: colorBorde, width: 1.5),
                        ),
                        child: const Center(
                          child: Icon(Icons.arrow_back, color: colorTextoPrincipal, size: 22),
                        ),
                      ),
                    )),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Perfil del responsable',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colorTextoPrincipal,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cuéntanos quién acompañará al niño o niña en la app.',
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: 16,
                          height: 1.4,
                          color: colorTextoSecundario,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 22),

                      _buildEtiqueta('Nombre'),
                      const SizedBox(height: 6),
                      _buildInputContainer(
                        tieneError: errorNombre != null,
                        child: TextField(
                          controller: _nombreCtrl,
                          focusNode: _nombreFocus,
                          keyboardType: TextInputType.name,
                          maxLines: 1,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          onEditingComplete: () => _enfocarYDesplazar(_apellidoPaternoFocus),
                          onSubmitted: (_) => _enfocarYDesplazar(_apellidoPaternoFocus),
                          inputFormatters: [
                            SinTildesFormatter(),
                            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZñÑ\s]")),
                            LengthLimitingTextInputFormatter(35),
                          ],
                          style: const TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorTextoPrincipal,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ej. Maria Elena',
                            hintStyle: TextStyle(color: colorPista, fontSize: 16),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => _asegurarSinTildes(_nombreCtrl),
                        ),
                      ),
                      if (errorNombre != null) _buildTextoError(errorNombre),

                      const SizedBox(height: 16),

                      _buildEtiqueta('Apellido paterno'),
                      const SizedBox(height: 6),
                      _buildInputContainer(
                        tieneError: errorPaterno != null,
                        child: TextField(
                          controller: _apellidoPaternoCtrl,
                          focusNode: _apellidoPaternoFocus,
                          keyboardType: TextInputType.name,
                          maxLines: 1,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          onEditingComplete: () => _enfocarYDesplazar(_apellidoMaternoFocus),
                          onSubmitted: (_) => _enfocarYDesplazar(_apellidoMaternoFocus),
                          inputFormatters: [
                            SinTildesFormatter(),
                            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZñÑ\s]")),
                            LengthLimitingTextInputFormatter(35),
                          ],
                          style: const TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorTextoPrincipal,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ej. Gomez',
                            hintStyle: TextStyle(color: colorPista, fontSize: 16),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => _asegurarSinTildes(_apellidoPaternoCtrl),
                        ),
                      ),
                      if (errorPaterno != null) _buildTextoError(errorPaterno),

                      const SizedBox(height: 16),

                      _buildEtiqueta('Apellido materno'),
                      const SizedBox(height: 6),
                      _buildInputContainer(
                        tieneError: errorMaterno != null,
                        child: TextField(
                          controller: _apellidoMaternoCtrl,
                          focusNode: _apellidoMaternoFocus,
                          keyboardType: TextInputType.name,
                          maxLines: 1,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          onEditingComplete: () => _enfocarYDesplazar(_diaFocus),
                          onSubmitted: (_) => _enfocarYDesplazar(_diaFocus),
                          inputFormatters: [
                            SinTildesFormatter(),
                            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZñÑ\s]")),
                            LengthLimitingTextInputFormatter(35),
                          ],
                          style: const TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorTextoPrincipal,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ej. Ruiz',
                            hintStyle: TextStyle(color: colorPista, fontSize: 16),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => _asegurarSinTildes(_apellidoMaternoCtrl),
                        ),
                      ),
                      if (errorMaterno != null) _buildTextoError(errorMaterno),

                      const SizedBox(height: 16),

                      _buildEtiqueta('Fecha de nacimiento'),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 76,
                            child: _buildInputContainer(
                              tieneError: errorDia != null,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: _diaCtrl,
                                focusNode: _diaFocus,
                                keyboardType: TextInputType.number,
                                maxLines: 1,
                                textInputAction: TextInputAction.next,
                                textAlign: TextAlign.center,
                                maxLength: 2,
                                onEditingComplete: () => _enfocarYDesplazar(_anioFocus),
                                onSubmitted: (_) => _enfocarYDesplazar(_anioFocus),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(2),
                                ],
                                style: const TextStyle(
                                  fontFamily: 'Atkinson Hyperlegible Next',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorTextoPrincipal,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'DD',
                                  hintStyle: TextStyle(color: colorPista, fontSize: 16),
                                  counterText: '',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (v) {
                                  if (v.length == 2) {
                                    _enfocarYDesplazar(_anioFocus);
                                  }
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _abrirSelectorMes,
                              borderRadius: BorderRadius.circular(12),
                              child: _buildInputContainer(
                                tieneError: errorMes != null,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _mesSeleccionado ?? 'Mes',
                                      style: TextStyle(
                                        fontFamily: 'Atkinson Hyperlegible Next',
                                        fontSize: 16,
                                        fontWeight: _mesSeleccionado != null ? FontWeight.w600 : FontWeight.w400,
                                        color: _mesSeleccionado != null ? colorTextoPrincipal : colorPista,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: colorTextoSecundario, size: 22),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            child: _buildInputContainer(
                              tieneError: errorAnio != null,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: _anioCtrl,
                                focusNode: _anioFocus,
                                keyboardType: TextInputType.number,
                                maxLines: 1,
                                textInputAction: TextInputAction.next,
                                textAlign: TextAlign.center,
                                maxLength: 4,
                                onEditingComplete: () => _enfocarYDesplazar(_ciudadFocus),
                                onSubmitted: (_) => _enfocarYDesplazar(_ciudadFocus),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                style: const TextStyle(
                                  fontFamily: 'Atkinson Hyperlegible Next',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colorTextoPrincipal,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'AAAA',
                                  hintStyle: TextStyle(color: colorPista, fontSize: 16),
                                  counterText: '',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (v) {
                                  if (v.length == 4) {
                                    _enfocarYDesplazar(_ciudadFocus);
                                  }
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (errorDia != null || errorMes != null || errorAnio != null)
                        _buildTextoError(errorDia ?? errorMes ?? errorAnio!),

                      const SizedBox(height: 16),

                      _buildEtiqueta('Ciudad de nacimiento'),
                      const SizedBox(height: 6),
                      _buildInputContainer(
                        tieneError: errorCiudad != null,
                        child: TextField(
                          controller: _ciudadCtrl,
                          focusNode: _ciudadFocus,
                          keyboardType: TextInputType.text,
                          maxLines: 1,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.words,
                          onEditingComplete: () => FocusScope.of(context).unfocus(),
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          inputFormatters: [
                            SinTildesFormatter(),
                            FilteringTextInputFormatter.allow(RegExp(r"[a-zA-ZñÑ\s]")),
                            LengthLimitingTextInputFormatter(35),
                          ],
                          style: const TextStyle(
                            fontFamily: 'Atkinson Hyperlegible Next',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorTextoPrincipal,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Ej. Lima',
                            hintStyle: TextStyle(color: colorPista, fontSize: 16),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => _asegurarSinTildes(_ciudadCtrl),
                        ),
                      ),
                      if (errorCiudad != null) _buildTextoError(errorCiudad),

                      const SizedBox(height: 16),

                      _buildEtiqueta('Sexo'),
                      const SizedBox(height: 6),
                      Row(
                        children: ['Femenino', 'Masculino', 'Otro'].map((s) {
                          final sel = _sexoSeleccionado == s;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0),
                              child: InkWell(
                                onTap: () => setState(() => _sexoSeleccionado = s),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: sel ? colorTealPrimario : colorInput,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: sel ? colorTealPrimario : colorBorde,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      s,
                                      style: TextStyle(
                                        fontFamily: 'Atkinson Hyperlegible Next',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: sel ? Colors.white : colorTextoPrincipal,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      _buildEtiqueta('Parentesco con el niño o niña'),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _abrirSelectorParentesco,
                        borderRadius: BorderRadius.circular(12),
                        child: _buildInputContainer(
                          tieneError: errorParentesco != null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _parentescoSeleccionado ?? 'Selecciona una opción',
                                style: TextStyle(
                                  fontFamily: 'Atkinson Hyperlegible Next',
                                  fontSize: 16,
                                  fontWeight: _parentescoSeleccionado != null ? FontWeight.w600 : FontWeight.w400,
                                  color: _parentescoSeleccionado != null ? colorTextoPrincipal : colorPista,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: colorTextoSecundario, size: 24),
                            ],
                          ),
                        ),
                      ),
                      if (errorParentesco != null) _buildTextoError(errorParentesco),

                      const SizedBox(height: 24),

                      // Botón continuar integrado al final del scroll si el teclado está abierto
                      if (tecladoVisible)
                        _buildBotonContinuar(formValido),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBotonContinuar(bool formValido) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _continuar,
        style: ElevatedButton.styleFrom(
          backgroundColor: formValido ? colorTealPrimario : colorBotonDeshabilitado,
          disabledBackgroundColor: colorBotonDeshabilitado,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          'Continuar',
          style: TextStyle(
            fontFamily: 'Atkinson Hyperlegible Next',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: formValido ? Colors.white : const Color(0xFF8E9598),
          ),
        ),
      ),
    );
  }

  Widget _buildEtiqueta(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontFamily: 'Atkinson Hyperlegible Next',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorTextoSecundario,
      ),
    );
  }

  Widget _buildTextoError(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0, left: 4.0),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 14, color: colorError),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontFamily: 'Atkinson Hyperlegible Next',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: colorError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    bool tieneError = false,
  }) {
    return Container(
      height: 56,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: colorInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tieneError ? colorError : colorBorde,
          width: tieneError ? 1.8 : 1.5,
        ),
      ),
      child: child,
    );
  }
}
