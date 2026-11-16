import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Entrada de PIN en recuadros. Usa un solo TextField invisible para que la tecla Borrar funcione en
/// todos los teclados de Android (Gboard, Samsung, SwiftKey); tocar un recuadro anterior permite
/// reescribir desde allí.
class PinInputCuadros extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final int length;
  final bool obscureText;
  final String obscuringCharacter;
  final bool esError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final double boxWidth;
  final double boxHeight;
  final double boxMargin;
  final double borderRadius;
  final double fontSize;
  final bool autofocus;
  final bool enabled;

  const PinInputCuadros({
    super.key,
    required this.controller,
    this.focusNode,
    this.length = 4,
    this.obscureText = true,
    this.obscuringCharacter = '•',
    this.esError = false,
    this.onChanged,
    this.onCompleted,
    this.boxWidth = 67,
    this.boxHeight = 77,
    this.boxMargin = 5,
    this.borderRadius = 12,
    this.fontSize = 28,
    this.autofocus = true,
    this.enabled = true,
  });

  @override
  State<PinInputCuadros> createState() => _PinInputCuadrosState();
}

class _PinInputCuadrosState extends State<PinInputCuadros> {
  static const Color colorBorde = Color(0xFFDDD6C9);
  static const Color colorCasillaInactiva = Color(0xFFEFEAE2);
  static const Color colorTextoPrincipal = Color(0xFF3A3A3A);
  static const Color colorTealPrimario = Color(0xFF3D6D7E);
  static const Color colorErrorFondo = Color(0xFFFDE8E8);
  static const Color colorErrorBorde = Color(0xFFE05252);
  static const Color colorErrorTexto = Color(0xFFC53030);

  late FocusNode _focusNode;
  bool _internalFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _internalFocusNode = true;
    }
    widget.controller.addListener(_onControllerChange);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant PinInputCuadros oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      if (_internalFocusNode) {
        _focusNode.dispose();
        _internalFocusNode = false;
      } else {
        oldWidget.focusNode?.removeListener(_onFocusChange);
      }
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
      } else {
        _focusNode = FocusNode();
        _internalFocusNode = true;
      }
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _focusNode.removeListener(_onFocusChange);
    if (_internalFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onControllerChange() {
    // Asegurar que el cursor siempre esté al final para que borrar y escribir sea natural
    if (widget.controller.selection.baseOffset != widget.controller.text.length) {
      widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
    }
    if (mounted) setState(() {});
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _onBoxTap(int index) {
    if (!widget.enabled) return;
    _focusNode.requestFocus();
    // Si pulsa un recuadro ya completado o previo, retroceder y borrar hasta ese índice
    if (index < widget.controller.text.length) {
      final nuevoTexto = widget.controller.text.substring(0, index);
      widget.controller.text = nuevoTexto;
      widget.controller.selection = TextSelection.collapsed(offset: nuevoTexto.length);
      widget.onChanged?.call(nuevoTexto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final hasFocus = _focusNode.hasFocus;
    final activeIndex = text.length < widget.length ? text.length : widget.length - 1;

    final totalItemWidth = widget.boxWidth + (widget.boxMargin * 2);
    final totalRowWidth = totalItemWidth * widget.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            if (!widget.enabled) return;
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) return;
            final localX = renderBox.globalToLocal(event.position).dx;
            final rowStartX = (renderBox.size.width - totalRowWidth) / 2;
            final relX = localX - rowStartX;
            if (relX >= 0 && relX <= totalRowWidth) {
              final boxIndex = (relX / totalItemWidth).floor();
              if (boxIndex >= 0 && boxIndex < widget.length) {
                _onBoxTap(boxIndex);
              }
            } else {
              _focusNode.requestFocus();
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Recuadros visibles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.length, (index) {
                  final hasChar = index < text.length;
                  final isBoxActive = hasFocus && (index == activeIndex);

                  Color bg;
                  Color border;
                  double borderWidth;
                  Color txtColor;

                  if (widget.esError) {
                    bg = colorErrorFondo;
                    border = colorErrorBorde;
                    borderWidth = 2.0;
                    txtColor = colorErrorTexto;
                  } else if (isBoxActive) {
                    bg = Colors.white;
                    border = colorTealPrimario;
                    borderWidth = 2.0;
                    txtColor = colorTextoPrincipal;
                  } else {
                    bg = colorCasillaInactiva;
                    border = hasChar ? colorTealPrimario.withValues(alpha: 0.5) : colorBorde;
                    borderWidth = 1.5;
                    txtColor = colorTextoPrincipal;
                  }

                  final displayChar = hasChar
                      ? (widget.obscureText ? widget.obscuringCharacter : text[index])
                      : '';

                  return Container(
                    width: widget.boxWidth,
                    height: widget.boxHeight,
                    margin: EdgeInsets.symmetric(horizontal: widget.boxMargin),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(color: border, width: borderWidth),
                    ),
                    child: Center(
                      child: Text(
                        displayChar,
                        style: TextStyle(
                          fontFamily: 'Atkinson Hyperlegible Next',
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w700,
                          color: txtColor,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // 2. TextField invisible que recibe lo que se escribe
              Positioned(
                width: totalRowWidth,
                height: widget.boxHeight,
                child: Opacity(
                  opacity: 0.001,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    showCursor: false,
                    enableInteractiveSelection: false,
                    style: const TextStyle(color: Colors.transparent, fontSize: 1),
                    cursorColor: Colors.transparent,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      fillColor: Colors.transparent,
                    ),
                    onChanged: (val) {
                      widget.onChanged?.call(val);
                      if (val.length == widget.length) {
                        widget.onCompleted?.call(val);
                      }
                    },
                    onSubmitted: (val) {
                      if (val.length == widget.length) {
                        widget.onCompleted?.call(val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
