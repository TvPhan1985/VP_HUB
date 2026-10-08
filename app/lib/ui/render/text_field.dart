import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import 'field_widget.dart';

/// text: chu chi doc (trang thai, thong bao)
class TextRow extends StatelessWidget {
  final FieldCtx c;
  const TextRow({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final v = c.value;
    final s = v == null || (v is String && v.isEmpty) ? S.noData : '$v';
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    // Chu dai thi xuong dong duoi nhan
    if (s.length > 18) {
      return FieldRow(label: c.field.label, below: Text(s, style: style));
    }
    return FieldRow(label: c.field.label, trailing: Text(s, style: style));
  }
}

/// str: o nhap chu, bam de mo hop nhap (max = do dai toi da)
class StrField extends StatelessWidget {
  final FieldCtx c;
  const StrField({super.key, required this.c});

  Future<String?> _ask(BuildContext context, String current) {
    final f = c.field;
    final max = f.max?.toInt();
    final ctl = TextEditingController(text: current);
    String? err;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          void submit() {
            final s = ctl.text.trim();
            if (s.isEmpty) {
              setState(() => err = S.notEmpty);
            } else if (max != null && s.length > max) {
              setState(() => err = S.maxLen(max));
            } else {
              Navigator.pop(ctx, s);
            }
          }

          return AlertDialog(
            title: Text(f.label),
            content: TextField(
              controller: ctl,
              autofocus: true,
              maxLength: max,
              decoration: InputDecoration(errorText: err),
              onSubmitted: (_) => submit(),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(S.cancel)),
              FilledButton(onPressed: submit, child: const Text(S.ok)),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = c.value == null ? '' : '${c.value}';
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    if (c.field.readOnly) {
      return FieldRow(label: c.field.label, trailing: Text(s.isEmpty ? S.noData : s, style: style));
    }
    return FieldRow(
      label: c.field.label,
      busy: c.busy,
      draft: c.draft,
      trailing: TextButton.icon(
        icon: const Icon(Icons.edit, size: 18),
        label: Text(s.isEmpty ? S.noData : s, style: style),
        onPressed: c.editable && !c.busy
            ? () async {
                final nv = await _ask(context, s);
                if (nv != null && nv != s) c.onChanged(nv);
              }
            : null,
      ),
    );
  }
}
