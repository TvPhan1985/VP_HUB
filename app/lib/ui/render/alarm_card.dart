import 'package:flutter/material.dart';

import '../../core/model/vph_value.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import 'field_widget.dart';
import 'flags_field.dart' show activeFlags;
import 'icons.dart';

/// Goi y alarm (flags hoac bool): the bao dong. Dang bao -> nen do, gach dau dong tung loi;
/// binh thuong -> dau tich xanh. [extras] la cac truong cung nhom `g`: act thanh nut o goc,
/// bool thanh den, text thanh mot dong gach dau dong.
class AlarmCard extends StatelessWidget {
  final FieldCtx c;
  final List<FieldCtx> extras;
  const AlarmCard({super.key, required this.c, this.extras = const []});

  @override
  Widget build(BuildContext context) {
    final f = c.field;
    final cs = Theme.of(context).colorScheme;
    final unknown = c.value == null;
    final flags = f.type == 'flags' ? activeFlags(f, c.value) : const <String>[];
    final on = f.type == 'flags' ? flags.isNotEmpty : asBool(c.value) == true;
    final fg = on ? cs.onErrorContainer : null;
    final bullets = <String>[
      ...flags,
      for (final e in extras)
        if (e.field.type == 'text' && e.value is String && (e.value as String).isNotEmpty) e.value as String,
    ];
    final leds = [
      for (final e in extras)
        if (e.field.type == 'bool' && asBool(e.value) == true) e.field,
    ];
    return Card(
      color: on ? cs.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(Vp.pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: Row(
                children: [
                  Icon(
                    on ? Icons.warning_amber_rounded : (unknown ? Icons.help_outline : Icons.check_circle),
                    color: on ? Vp.warn(cs) : (unknown ? Vp.idle(cs) : Vp.ok(cs)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      on ? f.label : (unknown ? '${f.label}: ${S.noData}' : S.alarmNone),
                      style: TextStyle(fontWeight: FontWeight.bold, color: fg),
                    ),
                  ),
                  for (final e in extras)
                    if (e.field.type == 'act')
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilledButton.tonalIcon(
                          onPressed: e.editable && !e.busy ? () => e.onChanged(1) : null,
                          icon: e.busy
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(vphIcon(e.field.icon) ?? Icons.touch_app_outlined, size: 18),
                          label: Text(e.field.label),
                        ),
                      ),
                ],
              ),
            ),
            for (final b in bullets)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 4),
                child: Text('• $b', style: TextStyle(color: fg)),
              ),
            for (final l in leds)
              Padding(
                padding: const EdgeInsets.only(left: 32, top: 6),
                child: Row(
                  children: [
                    Icon(vphIcon(l.icon) ?? Icons.check, size: 16, color: fg ?? cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Flexible(child: Text(l.label, style: TextStyle(color: fg, fontStyle: FontStyle.italic))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
