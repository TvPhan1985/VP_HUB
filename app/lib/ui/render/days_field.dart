import 'package:flutter/material.dart';

import '../../core/model/vph_value.dart';
import '../../l10n/strings_vi.dart';
import 'field_widget.dart';

/// days: bitmask 0..127, bit0 = Thu 2 ... bit6 = Chu nhat -> 7 nut T2..CN
class DaysField extends StatelessWidget {
  final FieldCtx c;
  const DaysField({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final mask = (asNum(c.value) ?? 0).toInt() & 0x7F;
    final can = c.editable && !c.busy && !c.field.readOnly;
    final cs = Theme.of(context).colorScheme;
    return FieldRow(
      label: c.field.label,
      busy: c.busy,
      draft: c.draft,
      below: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        child: Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Material(
                    color: mask & (1 << i) != 0 ? cs.primary : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: can ? () => c.onChanged(mask ^ (1 << i)) : null,
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        child: Text(
                          S.dayLabels[i],
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: mask & (1 << i) != 0 ? cs.onPrimary : cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
