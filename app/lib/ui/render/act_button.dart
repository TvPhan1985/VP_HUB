import 'package:flutter/material.dart';

import 'field_widget.dart';
import 'icons.dart';

/// act: nut bam, gui {"id":X,"v":1}. Cau hoi xac nhan `c` do FieldWidget lo.
class ActButton extends StatelessWidget {
  final FieldCtx c;
  const ActButton({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final ic = vphIcon(c.field.icon);
    final onPressed = c.editable && !c.busy ? () => c.onChanged(1) : null;
    final child = c.busy
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(c.field.label);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ic == null
          ? FilledButton.tonal(onPressed: onPressed, child: child)
          : FilledButton.tonalIcon(onPressed: onPressed, icon: Icon(ic, size: 18), label: child),
    );
  }
}
