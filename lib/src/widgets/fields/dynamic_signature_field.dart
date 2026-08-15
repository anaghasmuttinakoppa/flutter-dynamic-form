import 'package:flutter/material.dart';

import '../../controllers/dynamic_form_controller.dart';
import '../../l10n/dynamic_form_localizations.dart';
import '../../models/form_field_schema.dart';
import '../../theme/dynamic_form_theme.dart';

/// Freehand signature pad. Stores a list of stroke point maps.
class DynamicSignatureField extends StatefulWidget {
  /// Creates a [DynamicSignatureField].
  const DynamicSignatureField({
    super.key,
    required this.field,
    required this.controller,
    this.theme,
  });

  /// Field schema.
  final FormFieldSchema field;

  /// Form controller.
  final DynamicFormController controller;

  /// Theme.
  final DynamicFormTheme? theme;

  @override
  State<DynamicSignatureField> createState() => _DynamicSignatureFieldState();
}

class _DynamicSignatureFieldState extends State<DynamicSignatureField> {
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset>? _current;

  @override
  void initState() {
    super.initState();
    _loadFromController();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    // Avoid fighting with local drawing mid-gesture.
    if (_current != null) return;
    _loadFromController();
    if (mounted) setState(() {});
  }

  void _loadFromController() {
    final raw = widget.controller.getValue(widget.field.key);
    _strokes
      ..clear()
      ..addAll(_decode(raw));
  }

  List<List<Offset>> _decode(dynamic raw) {
    if (raw is! List) return const <List<Offset>>[];
    final strokes = <List<Offset>>[];
    for (final stroke in raw) {
      if (stroke is! List) continue;
      final points = <Offset>[];
      for (final point in stroke) {
        if (point is Map) {
          final x = (point['x'] as num?)?.toDouble();
          final y = (point['y'] as num?)?.toDouble();
          if (x != null && y != null) points.add(Offset(x, y));
        }
      }
      if (points.isNotEmpty) strokes.add(points);
    }
    return strokes;
  }

  List<List<Map<String, double>>> _encode() {
    return _strokes
        .map(
          (stroke) => stroke
              .map((p) => <String, double>{'x': p.dx, 'y': p.dy})
              .toList(),
        )
        .toList();
  }

  void _commit() {
    widget.controller.updateField(widget.field.key, _encode());
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? DynamicFormThemeProvider.of(context);
    final l10n = DynamicFormLocalizations.of(context);
    final field = widget.field;
    final enabled = widget.controller.isFieldEnabled(field);
    final error = widget.controller.errorFor(field.key);
    final material = Theme.of(context);

    return Semantics(
      label: field.effectiveSemanticLabel,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.effectiveLabel,
                  style: theme.labelStyle ?? material.textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: !enabled
                    ? null
                    : () {
                        setState(() {
                          _strokes.clear();
                          _current = null;
                        });
                        _commit();
                      },
                child: Text(l10n.clearLabel),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 160,
            decoration: BoxDecoration(
              border: Border.all(color: material.dividerColor),
              borderRadius: BorderRadius.circular(theme.borderRadius),
              color: material.colorScheme.surfaceContainerLowest,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(theme.borderRadius),
              child: AbsorbPointer(
                absorbing: !enabled,
                child: GestureDetector(
                  onPanStart: (details) {
                    setState(() {
                      _current = <Offset>[details.localPosition];
                      _strokes.add(_current!);
                    });
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _current?.add(details.localPosition);
                    });
                  },
                  onPanEnd: (_) {
                    _current = null;
                    _commit();
                  },
                  child: CustomPaint(
                    painter: _SignaturePainter(
                      strokes: _strokes,
                      color: material.colorScheme.onSurface,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error,
                style: theme.errorStyle ??
                    TextStyle(color: material.colorScheme.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes, required this.color});

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, 1.5, paint..style = PaintingStyle.fill);
          paint.style = PaintingStyle.stroke;
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
