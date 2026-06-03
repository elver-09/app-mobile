import 'dart:async';
import 'package:flutter/material.dart';

/// Botón que se muestra como flotante utilizando un [OverlayEntry].
///
/// Mantiene la misma API: `onPressed`, `enabled` y `visible`. No cambia
/// la funcionalidad — solo la presentación (flotante sobre la interfaz).
class ReprogramButton extends StatefulWidget {
  final FutureOr<void> Function()? onPressed;
  final bool enabled;
  final bool visible;

  const ReprogramButton({
    Key? key,
    this.onPressed,
    this.enabled = true,
    this.visible = false,
  }) : super(key: key);

  @override
  State<ReprogramButton> createState() => _ReprogramButtonState();
}

class _ReprogramButtonState extends State<ReprogramButton> {
  OverlayEntry? _entry;
  bool _overlayScheduled = false;
  bool _suspended =
      false; // evita reinsertar el overlay mientras la acción está activa

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverlay());
  }

  @override
  void didUpdateWidget(covariant ReprogramButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.onPressed != widget.onPressed) {
      _updateOverlay();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _updateOverlay() {
    // Evitar insertar/remover overlay durante la fase de build.
    if (_overlayScheduled) return;
    _overlayScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayScheduled = false;
      if (!mounted) return;

      final overlay = Overlay.of(context);
      if (!widget.visible) {
        _removeOverlay();
        _suspended = false;
        return;
      }

      // Si ya existe, reemplazar para reflejar cambios en enabled/onPressed
      if (_entry != null) {
        _entry!.remove();
        _entry = null;
      }

      if (_suspended) return;

      _entry = OverlayEntry(
        builder: (context) {
          final mq = MediaQuery.of(context);
          final bottomPadding = mq.viewPadding.bottom + 16.0;
          return Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding,
            child: SafeArea(
              minimum: const EdgeInsets.all(0),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: _buildButton(context),
                ),
              ),
            ),
          );
        },
      );

      // Insertar fuera de la fase de build
      overlay.insert(_entry!);
    });
  }

  void _removeOverlay() {
    if (_entry != null) {
      _entry!.remove();
      _entry = null;
    }
  }

  Widget _buildButton(BuildContext context) {
    final theme = Theme.of(context);

    // Gradiente basado en #123c80 para estado habilitado, y tonos grises para deshabilitado
    const enabledStart = Color(0xFF123C80);
    const enabledEnd = Color(0xFF0F2F66);
    const disabledStart = Color(0xFFCBD5E1);
    const disabledEnd = Color(0xFF94A3B8);

    final gradient = widget.enabled
        ? const LinearGradient(
            colors: [enabledStart, enabledEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [disabledStart, disabledEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          if (widget.enabled)
            BoxShadow(
              color: enabledEnd.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ElevatedButton(
          onPressed: widget.enabled
              ? () {
                  // Suspender reinserción y ocultar inmediatamente el overlay cuando se presiona
                  _suspended = true;
                  _removeOverlay();

                  // Ejecutar el callback del usuario. Si devuelve Future, volver a mostrar
                  // el overlay cuando termine. Si es síncrono, reinsertar en el siguiente frame.
                  final result = widget.onPressed?.call();
                  if (result is Future) {
                    result.whenComplete(() {
                      if (!mounted) return;
                      _suspended = false;
                      if (mounted && widget.visible) _updateOverlay();
                    });
                  } else {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _suspended = false;
                      if (mounted && widget.visible) _updateOverlay();
                    });
                  }
                }
              : null,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(Colors.transparent),
            shadowColor: MaterialStateProperty.all(Colors.transparent),
            elevation: MaterialStateProperty.all(0),
            foregroundColor: MaterialStateProperty.all(Colors.white),
            padding: MaterialStateProperty.all(
              const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            ),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'REPROGRAMAR',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // El widget en sí no ocupa espacio en el layout; su representación es el overlay.
    return const SizedBox.shrink();
  }
}
