import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import 'field_widget.dart';

final RegExp _hhmm = RegExp(r'^(\d{1,2}):(\d{2})');

String _two(int v) => v.toString().padLeft(2, '0');

/// time: "HH:MM", bam de mo bo chon gio 24h
class TimeField extends StatelessWidget {
  final FieldCtx c;
  const TimeField({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final f = c.field;
    final s = c.value is String ? c.value as String : null;
    final m = s == null ? null : _hhmm.firstMatch(s);
    final init = m == null
        ? const TimeOfDay(hour: 8, minute: 0)
        : TimeOfDay(hour: int.parse(m.group(1)!) % 24, minute: int.parse(m.group(2)!) % 60);
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    return FieldRow(
      label: f.label,
      busy: c.busy,
      draft: c.draft,
      trailing: f.readOnly
          ? Text(s ?? S.noData, style: style)
          : OutlinedButton.icon(
              icon: const Icon(Icons.schedule, size: 18),
              label: Text(s ?? S.noData, style: style),
              onPressed: c.editable && !c.busy
                  ? () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: init,
                        helpText: f.label,
                        builder: (ctx, child) => MediaQuery(
                          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        ),
                      );
                      if (t != null) c.onChanged('${_two(t.hour)}:${_two(t.minute)}');
                    }
                  : null,
            ),
    );
  }
}
