import 'package:flutter/material.dart';

import '../../core/consts.dart';
import 'field_widget.dart';
import 'icons.dart';

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
          f.optionLabel(c.value) ?? cur ?? kNoData,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      );
    }

    dynamic valueOf(String key) => f.options.firstWhere((o) => '${o.value}' == key).value;

    // Goi y seg: luon la nut chon, chiem ca chieu ngang, co icon
    final seg = f.hint('seg');
    if (seg || f.options.length <= 4) {
      Widget? icon(String? name) {
        final ic = vphIcon(name);
        return ic == null ? null : Icon(ic, size: 18);
      }

      return FieldRow(
        label: f.label,
        busy: c.busy,
        draft: c.draft,
        below: Padding(
          padding: EdgeInsets.only(top: seg ? 6 : 2, bottom: seg ? 6 : 2),
          child: SegmentedButton<String>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            expandedInsets: seg ? EdgeInsets.zero : null,
            style: seg ? null : const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              for (final o in f.options)
                ButtonSegment(
                  value: '${o.value}',
                  icon: icon(o.icon),
                  label: Text(o.label, overflow: TextOverflow.ellipsis),
                ),
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
        hint: Text(cur ?? kNoData),
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
