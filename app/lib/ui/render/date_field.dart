import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import 'field_widget.dart';
import 'num_field.dart' show NullSwitch;

String _two(int v) => v.toString().padLeft(2, '0');
String _ymd(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// Ngay hien cho nguoi dung: `dd MMM yyyy` theo ngon ngu dang chon (docs/COPY_STYLE.md).
/// Gia tri gui xuong thiet bi van la "YYYY-MM-DD".
String dateText(BuildContext context, DateTime d) {
  try {
    return DateFormat('dd MMM yyyy', Localizations.localeOf(context).toLanguageTag()).format(d);
  } catch (_) {
    return _ymd(d);
  }
}

/// date: "YYYY-MM-DD" hoac null (nul:1 thi co cong tac "Khong gioi han")
class DateField extends StatelessWidget {
  final FieldCtx c;
  const DateField({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final f = c.field;
    final s = c.value is String && (c.value as String).isNotEmpty ? c.value as String : null;
    final parsed = s == null ? null : DateTime.tryParse(s);
    final can = c.editable && !c.busy;
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final first = DateTime(2000), last = DateTime(2099, 12, 31);

    Future<void> pick() async {
      var init = parsed ?? DateTime.now();
      if (init.isBefore(first) || init.isAfter(last)) init = DateTime.now();
      final d = await showDatePicker(
        context: context,
        initialDate: init,
        firstDate: first,
        lastDate: last,
        helpText: f.label,
      );
      if (d != null) c.onChanged(_ymd(d));
    }

    final text = s == null
        ? (f.nullable ? context.l.noLimit : context.l.notSet)
        : (parsed == null ? s : dateText(context, parsed));
    return FieldRow(
      label: f.label,
      busy: c.busy,
      draft: c.draft,
      trailing: f.readOnly
          ? Text(text, style: style)
          : OutlinedButton.icon(
              icon: const Icon(Icons.event, size: 18),
              label: Text(text, style: style),
              onPressed: can ? pick : null,
            ),
      below: f.nullable && !f.readOnly
          ? NullSwitch(
              isNull: s == null,
              enabled: can,
              onChanged: (n) => c.onChanged(n ? null : _ymd(DateTime.now())),
            )
          : null,
    );
  }
}
