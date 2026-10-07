import 'package:flutter/material.dart';

import '../../core/model/vph_value.dart';
import '../theme.dart';
import 'field_widget.dart';
import 'icons.dart';

/// Goi y hero: the trang thai lon cua mot bool. Doi mau khi bat, co dong phu `sub`,
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
    final bg = on ? (warn ? cs.errorContainer : Vp.okContainer(cs)) : null;
    final fg = on ? (warn ? cs.onErrorContainer : Vp.onOkContainer(cs)) : null;
    final btns = f.hint('btns') && !f.readOnly;
    final desc = f.desc;
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(Vp.pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  vphIcon(f.icon) ?? Icons.power_settings_new,
                  size: 40,
                  color: on ? (warn ? Vp.warn(cs) : Vp.ok(cs)) : Vp.idle(cs),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${f.label}: ${boolText(f, state)}',
                        style: TextStyle(fontSize: Vp.heroTitle, fontWeight: FontWeight.bold, color: fg),
                      ),
                      if (subText != null) Text(subText!, style: TextStyle(color: fg)),
                    ],
                  ),
                ),
                if (c.busy)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                if (!btns && !f.readOnly)
                  Switch(value: on, onChanged: c.editable && !c.busy ? (v) => c.onChanged(v) : null),
              ],
            ),
            if (btns) ...[
              const SizedBox(height: 12),
              OnOffButtons(c: c),
            ],
            if (locked && desc != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(desc, style: TextStyle(fontSize: 12, color: fg)),
              ),
          ],
        ),
      ),
    );
  }
}
