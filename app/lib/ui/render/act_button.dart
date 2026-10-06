import 'package:flutter/material.dart';

import 'field_widget.dart';

/// act: nut bam, gui {"id":X,"v":1}. Cau hoi xac nhan `c` do FieldWidget lo.
class ActButton extends StatelessWidget {
  final FieldCtx c;
  const ActButton({super.key, required this.c});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: FilledButton.tonal(
          onPressed: c.editable && !c.busy ? () => c.onChanged(1) : null,
          child: c.busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(c.field.label),
        ),
      );
}
