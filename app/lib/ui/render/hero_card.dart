import 'package:flutter/material.dart';

import '../../core/model/vph_value.dart';
import '../theme.dart';
import '../vp_widgets.dart';
import 'field_widget.dart';
import 'icons.dart';

/// Goi y hero: the trang thai lon cua mot bool. Nhan trang thai o goc phai, co dong phu `sub`,
/// nut BẬT/TẮT ben trong neu co `btns`, dong `d` khi bi khoa.
class HeroCard extends StatelessWidget {
  final FieldCtx c;

  /// Dong phu da dung san ("Chế độ: Tự động"), null neu khong co `sub`
  final String? subText;

  /// Truong dang bi khoa boi dieu kien `en`
  final bool locked;
  const HeroCard({super.key, required this.c, this.subText, this.locked = false});

  @override
  Widget build(BuildContext context) {
    final f = c.field;
    final cs = Theme.of(context).colorScheme;
    final state = asBool(c.value);
    final on = state == true;
    final warn = f.hint('warn');
    final btns = f.hint('btns') && !f.readOnly;
    final desc = f.desc;
    final accent = on ? (warn ? Vp.warn(cs) : Vp.ok(cs)) : Vp.idle(cs);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Vp.pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dong tieu de: ten + nhan trang thai o goc phai
            Row(
              children: [
                Icon(vphIcon(f.icon) ?? Icons.power_settings_new, size: 28, color: accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    f.label,
                    style: TextStyle(fontSize: Vp.heroTitle, fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                ),
                if (c.busy)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                StatusChip(
                  text: boolText(f, state),
                  kind: on ? (warn ? ChipKind.stop : ChipKind.ok) : ChipKind.idle,
                ),
                if (!btns && !f.readOnly)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Switch(value: on, onChanged: c.editable && !c.busy ? (v) => c.onChanged(v) : null),
                  ),
              ],
            ),
            if (subText != null) ...[
              const SizedBox(height: 10),
              AccentWell(
                accent: accent,
                child: Text(subText!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
              ),
            ],
            if (btns) ...[
              const SizedBox(height: 12),
              OnOffButtons(c: c),
            ],
            if (locked && desc != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(desc, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ),
          ],
        ),
      ),
    );
  }
}
