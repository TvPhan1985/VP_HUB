import 'package:flutter/material.dart';

import '../../l10n/strings_vi.dart';
import 'field_widget.dart';

/// enum: nut chon (<= 4 muc) hoac danh sach tha
class EnumField extends StatelessWidget {
  final FieldCtx c;
  const EnumField({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final f = c.field;
    final cur = c.value == null ? null : '${c.value}';
    final can = c.editable && !c.busy;
    final known = f.options.any((o) => '${o.value}' == cur);

    if (f.readOnly || f.options.isEmpty) {
      return FieldRow(
        label: f.label,
        busy: c.busy,
        draft: c.draft,
        trailing: Text(
          f.optionLabel(c.value) ?? cur ?? S.noData,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      );
    }

    dynamic valueOf(String key) => f.options.firstWhere((o) => '${o.value}' == key).value;

    if (f.options.length <= 4) {
      return FieldRow(
        label: f.label,
        busy: c.busy,
        draft: c.draft,
        below: Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              for (final o in f.options)
                ButtonSegment(value: '${o.value}', label: Text(o.label, overflow: TextOverflow.ellipsis)),
            ],
            selected: {if (known) cur!},
            onSelectionChanged: can
                ? (s) {
                    if (s.isNotEmpty && s.first != cur) c.onChanged(valueOf(s.first));
                  }
                : null,
          ),
        ),
      );
    }

    return FieldRow(
      label: f.label,
      busy: c.busy,
      draft: c.draft,
      trailing: DropdownButton<String>(
        value: known ? cur : null,
        hint: Text(cur ?? S.noData),
        underline: const SizedBox.shrink(),
        items: [for (final o in f.options) DropdownMenuItem(value: '${o.value}', child: Text(o.label))],
        onChanged: can
            ? (k) {
                if (k != null && k != cur) c.onChanged(valueOf(k));
              }
            : null,
      ),
    );
  }
}
