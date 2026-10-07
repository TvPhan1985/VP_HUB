import 'package:flutter/material.dart';

import '../../core/model/vph_schema.dart';
import '../../core/model/vph_value.dart';
import '../../l10n/strings_vi.dart';
import '../theme.dart';
import 'field_widget.dart';

/// Nhan cua cac bit dang bat trong mot truong flags
List<String> activeFlags(VphField f, dynamic value) {
  final mask = (asNum(value) ?? 0).toInt();
  return [
    for (var i = 0; i < 31; i++)
      if (mask & (1 << i) != 0) i < f.flagLabels.length ? f.flagLabels[i] : S.flagBit(i),
  ];
}

/// flags: danh sach canh bao, do khi khac 0
class FlagsField extends StatelessWidget {
  final FieldCtx c;
  const FlagsField({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = activeFlags(c.field, c.value);
    if (c.value == null || active.isEmpty) {
      return FieldRow(
        label: c.field.label,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(c.value == null ? Icons.help_outline : Icons.check_circle,
                color: c.value == null ? Vp.idle(cs) : Vp.ok(cs), size: 20),
            const SizedBox(width: 6),
            Text(c.value == null ? S.noData : S.flagsNone),
          ],
        ),
      );
    }
    return FieldRow(
      label: c.field.label,
      trailing: Icon(Icons.warning_amber_rounded, color: cs.error),
      below: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final a in active)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: cs.errorContainer, borderRadius: BorderRadius.circular(8)),
              child: Text(a, style: TextStyle(color: cs.onErrorContainer, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
