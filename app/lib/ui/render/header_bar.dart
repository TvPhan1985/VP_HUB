import 'package:flutter/material.dart';

import '../../core/device_session.dart';
import '../../core/model/vph_value.dart';
import 'field_widget.dart' show LedDot;
import 'flags_field.dart' show activeFlags;
import 'num_field.dart' show numText;

/// Thanh dau trang: cac truong `hdr` hien gon tren moi tab (so, den, co bao dong do)
class HeaderBar extends StatelessWidget {
  final DeviceSession session;
  const HeaderBar({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final hdr = session.info?.hdr ?? const <String>[];
    if (hdr.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final items = <Widget>[];
    final cur = session.current < session.screens.length ? session.screens[session.current] : null;
    for (final id in hdr) {
      // Truong dang hien ngay trong tab nay thi khong lap lai o thanh dau trang
      if (cur?.field(id) != null) continue;
      final f = session.fieldById(id);
      final v = session.values[id];
      final label = f?.label ?? id;
      final type = f?.type ?? (v is bool ? 'bool' : (v is num ? 'num' : 'text'));
      Widget chip(Widget child, {Color? color}) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color ?? cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: child,
          );
      Widget pair(String value) => Text.rich(
            TextSpan(children: [
              TextSpan(text: '$label  ', style: theme.textTheme.bodySmall),
              TextSpan(text: value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          );
      switch (type) {
        case 'flags':
          if (f == null || v == null) break;
          final active = activeFlags(f, v);
          if (active.isEmpty) break;
          items.add(chip(
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: cs.onErrorContainer),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  active.length == 1 ? active.first : '${active.first} +${active.length - 1}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w700),
                ),
              ),
            ]),
            color: cs.errorContainer,
          ));
        case 'bool':
          final on = asBool(v);
          final warn = f?.hint('warn') ?? false;
          // Den canh bao chi hien khi dang bat, de thanh dau trang gon
          if (warn && on != true) break;
          items.add(chip(
            Row(mainAxisSize: MainAxisSize.min, children: [
              LedDot(on: on, warn: warn, size: 12),
              const SizedBox(width: 6),
              Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600, color: warn ? cs.onErrorContainer : null)),
            ]),
            color: warn ? cs.errorContainer : null,
          ));
        case 'num':
          items.add(chip(pair(f == null ? (v == null ? '--' : fmtNum(asNum(v) ?? 0)) : numText(f, v))));
        case 'enum':
          items.add(chip(pair(f?.optionLabel(v) ?? '${v ?? '--'}')));
        default:
          items.add(chip(pair('${v ?? '--'}')));
      }
    }
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Wrap(spacing: 6, runSpacing: 6, children: items),
    );
  }
}
