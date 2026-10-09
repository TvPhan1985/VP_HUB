import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/model/vph_schema.dart';
import '../../core/model/vph_value.dart';
import '../../core/consts.dart';
import '../../l10n/l10n.dart';
import '../theme.dart';
import '../vp_widgets.dart';
import 'field_widget.dart';
import 'icons.dart';

String numText(AppLocalizations l, VphField f, dynamic value, {bool withUnit = true}) {
  final x = asNum(value);
  if (x == null) return kNoData;
  if (f.hint('dur')) return durText(l, x);
  final s = fmtNum(x, dp: f.decimals);
  return withUnit && f.unit != null ? '$s ${f.unit}' : s;
}

/// Goi y dur: so giay -> "2 h 05 min" / "5 min 12 s"
String durText(AppLocalizations l, double seconds) {
  final t = seconds.isFinite && seconds > 0 ? seconds.round() : 0;
  final d = t ~/ 86400, h = (t % 86400) ~/ 3600, m = (t % 3600) ~/ 60;
  // Don vi sau luon 2 chu so: "2 h 05 min" (docs/COPY_STYLE.md)
  String two(int v) => v.toString().padLeft(2, '0');
  if (d > 0) return l.durDH('$d', two(h));
  if (h > 0) return l.durHM('$h', two(m));
  return l.durMS('$m', two(t % 60));
}

/// So gui di: so nguyen thi gui dang nguyen cho gon
dynamic _wire(double x) => x == x.roundToDouble() && x.abs() < 1e15 ? x.toInt() : x;

String? _rangeError(AppLocalizations l, VphField f, double x) {
  final lo = f.min, hi = f.max;
  String t(double v) => fmtNum(v, dp: f.decimals);
  if (lo != null && hi != null && (x < lo || x > hi)) return l.outOfRange(t(lo), t(hi));
  if (lo != null && x < lo) return l.atLeast(t(lo));
  if (hi != null && x > hi) return l.atMost(t(hi));
  return null;
}

/// Hop nhap so, kiem tra so bo theo min/max. Tra null neu huy.
Future<double?> showNumberDialog(BuildContext context, VphField f, double? current) {
  final ctl = TextEditingController(text: current == null ? '' : fmtNum(current, dp: f.decimals));
  ctl.selection = TextSelection(baseOffset: 0, extentOffset: ctl.text.length);
  String? err;
  return showDialog<double>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        void submit() {
          final x = asNum(ctl.text);
          final e = x == null ? context.l.invalidNumber : _rangeError(context.l, f, x);
          if (e != null) {
            setState(() => err = e);
          } else {
            Navigator.pop(ctx, x);
          }
        }

        return AlertDialog(
          title: Text(f.label),
          content: TextField(
            controller: ctl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: InputDecoration(
              suffixText: f.unit,
              errorText: err,
              helperText: f.min != null && f.max != null
                  ? context.l.rangeHint(fmtNum(f.min!, dp: f.decimals), fmtNum(f.max!, dp: f.decimals))
                  : null,
            ),
            onSubmitted: (_) => submit(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l.cancel)),
            FilledButton(onPressed: submit, child: Text(context.l.apply)),
          ],
        );
      },
    ),
  );
}

class NumField extends StatelessWidget {
  final FieldCtx c;
  const NumField({super.key, required this.c});

  void _step(double x, int dir) {
    final f = c.field;
    final st = f.step!;
    var nv = roundTo(x + dir * st, math.max(decimalsOf(st), f.decimals ?? 0));
    if (f.min != null && nv < f.min!) nv = f.min!;
    if (f.max != null && nv > f.max!) nv = f.max!;
    if (nv != x) c.onChanged(_wire(nv));
  }

  @override
  Widget build(BuildContext context) {
    final f = c.field;
    final x = asNum(c.value);
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final can = c.editable && !c.busy;

    Widget? below;
    if (f.hint('gauge') && f.min != null && f.max != null) {
      below = Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox(height: 110, child: GaugeView(value: x, min: f.min!, max: f.max!, text: numText(context.l, f, x))),
      );
    }

    if (f.readOnly) {
      return FieldRow(
        label: f.label,
        busy: c.busy,
        draft: c.draft,
        below: below,
        trailing: Text(numText(context.l, f, x), style: valueStyle),
      );
    }

    final unlimited = f.nullable && c.value == null;
    final stepper = f.step != null && f.step! > 0 && x != null;
    final value = TextButton(
      onPressed: can && !unlimited
          ? () async {
              final nv = await showNumberDialog(context, f, x);
              if (nv != null) c.onChanged(_wire(nv));
            }
          : null,
      child: Text(unlimited ? context.l.noLimit : numText(context.l, f, x), style: valueStyle),
    );
    return FieldRow(
      label: f.label,
      busy: c.busy,
      draft: c.draft,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stepper)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: can ? () => _step(x, -1) : null,
            ),
          value,
          if (stepper)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: can ? () => _step(x, 1) : null,
            ),
        ],
      ),
      below: f.nullable
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [?below, NullSwitch(isNull: unlimited, enabled: can, onChanged: (n) => c.onChanged(n ? null : _wire(f.min ?? 0)))],
            )
          : below,
    );
  }
}

/// Cong tac "Khong gioi han" cho truong co nul:1
class NullSwitch extends StatelessWidget {
  final bool isNull;
  final bool enabled;
  final void Function(bool isNull) onChanged;
  const NullSwitch({super.key, required this.isNull, required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(context.l.noLimit, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: 4),
          Switch(
            value: isNull,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      );
}

/// The so lon giua man hinh (goi y big)
class BigValueCard extends StatelessWidget {
  final VphField field;
  final dynamic value;
  const BigValueCard({super.key, required this.field, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final x = asNum(value);
    final cs = theme.colorScheme;
    final ic = vphIcon(field.icon);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Vp.pad),
        child: AccentWell(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(field.label, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            x == null ? kNoData : fmtNum(x, dp: field.decimals ?? 1),
                            style: TextStyle(
                                fontSize: Vp.bigNumber, fontWeight: FontWeight.w700, height: 1.15, color: cs.onSurface),
                          ),
                          if (field.unit != null) ...[
                            const SizedBox(width: 6),
                            Text(field.unit!,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (ic != null) Icon(ic, size: 36, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dong ho kim nua vong tron (goi y gauge)
class GaugeView extends StatelessWidget {
  final double? value;
  final double min, max;
  final String text;
  const GaugeView({super.key, required this.value, required this.min, required this.max, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _GaugePainter(
        frac: value == null || max <= min ? null : ((value! - min) / (max - min)).clamp(0.0, 1.0),
        track: cs.surfaceContainerHighest,
        fill: cs.primary,
        needle: cs.onSurface,
      ),
      child: Align(
        alignment: const Alignment(0, 0.95),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double? frac;
  final Color track, fill, needle;
  _GaugePainter({required this.frac, required this.track, required this.fill, required this.needle});

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width / 2, size.height - 24) - 8;
    final center = Offset(size.width / 2, size.height - 26);
    final rect = Rect.fromCircle(center: center, radius: r);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, p..color = track);
    final fr = frac;
    if (fr == null) return;
    canvas.drawArc(rect, math.pi, math.pi * fr, false, p..color = fill);
    final a = math.pi + math.pi * fr;
    canvas.drawLine(
      center,
      center + Offset(math.cos(a), math.sin(a)) * (r - 12),
      Paint()
        ..color = needle
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 5, Paint()..color = needle);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.frac != frac || old.fill != fill;
}
