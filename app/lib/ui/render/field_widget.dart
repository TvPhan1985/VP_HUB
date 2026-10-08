import 'package:flutter/material.dart';

import '../../core/cond.dart';
import '../../core/device_session.dart';
import '../../core/model/vph_schema.dart';
import '../../core/model/vph_value.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import 'act_button.dart';
import 'date_field.dart';
import 'days_field.dart';
import 'enum_field.dart';
import 'flags_field.dart';
import 'icons.dart';
import 'note_line.dart';
import 'num_field.dart';
import 'text_field.dart';
import 'time_field.dart';

/// Du lieu mot truong da tinh san cho cac widget ve
class FieldCtx {
  final VphField field;
  final dynamic value;
  final bool editable;
  final bool busy;
  final bool draft;
  final void Function(dynamic v) onChanged;
  const FieldCtx({
    required this.field,
    required this.value,
    required this.editable,
    required this.busy,
    required this.draft,
    required this.onChanged,
  });
}

/// Chu cua trang thai bool: theo `opt` cua truong, mac dinh BẬT / TẮT
String boolText(VphField f, bool? on) {
  if (on == null) return S.noData;
  final l = f.boolLabels;
  if (l != null) return on ? l[1] : l[0];
  return on ? S.onCaps : S.offCaps;
}

/// Gia tri mot truong dang chu (dung cho dong phu `sub`, the tile, o mini)
String displayValue(VphField? f, dynamic v) {
  if (v == null || (v is String && v.isEmpty)) return S.noData;
  if (f == null) return '$v';
  switch (f.type) {
    case 'num':
      return numText(f, v);
    case 'bool':
      return boolText(f, asBool(v));
    case 'enum':
      return f.optionLabel(v) ?? '$v';
  }
  return '$v';
}

/// Tinh san du lieu ve cho mot truong; hoi xac nhan `c` truoc khi gui
FieldCtx fieldCtx(BuildContext context, DeviceSession session, int screen, VphField f, Map<String, dynamic> cond) {
  return FieldCtx(
    field: f,
    value: session.valueOf(screen, f.id),
    editable: session.ready && !session.saving && !f.readOnly && evalCond(f.enCond, cond),
    busy: session.busy.contains(f.id),
    draft: session.isDraft(screen, f.id),
    onChanged: (v) async {
      final c = f.confirm;
      // Cong tac chi hoi lai khi bat (vd dot lo), tat thi lam ngay
      final ask = c != null && (f.type != 'bool' || v == true);
      if (ask && !await confirmDialog(context, c)) return;
      await session.edit(screen, f, v);
    },
  );
}

/// Icon va chu thich cua truong dang ve, de FieldRow tu hien (khong phai truyen qua tung widget)
class FieldDeco extends InheritedWidget {
  final String? icon;
  final String? desc;

  /// Truong dang bi khoa boi `en`: chu thich hien ro hon
  final bool strong;
  const FieldDeco({super.key, this.icon, this.desc, this.strong = false, required super.child});

  static FieldDeco? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<FieldDeco>();

  @override
  bool updateShouldNotify(FieldDeco old) => old.icon != icon || old.desc != desc || old.strong != strong;
}

Future<bool> confirmDialog(BuildContext context, String question) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text(S.confirmTitle),
      content: Text(question),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text(S.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text(S.ok)),
      ],
    ),
  );
  return yes == true;
}

/// Mot hang: nhan ben trai, noi dung ben phai; co vong cho nho va danh dau "dang sua"
class FieldRow extends StatelessWidget {
  final String label;
  final Widget? trailing;
  final Widget? below;
  final bool busy;
  final bool draft;
  const FieldRow({super.key, required this.label, this.trailing, this.below, this.busy = false, this.draft = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final deco = FieldDeco.maybeOf(context);
    final ic = vphIcon(deco?.icon);
    final desc = deco?.desc;
    return Container(
      // Truong dang sua chua luu (man batch) co vien mau khac
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: draft ? cs.tertiary : Colors.transparent, width: 3)),
        color: draft ? cs.tertiaryContainer.withValues(alpha: 0.35) : null,
      ),
      padding: const EdgeInsets.fromLTRB(11, 6, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Row(
              children: [
                if (ic != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(ic, size: 20, color: cs.onSurfaceVariant),
                  ),
                Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ?trailing,
              ],
            ),
          ),
          ?below,
          if (desc != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Text(
                desc,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: deco!.strong ? cs.primary : cs.onSurfaceVariant,
                      fontWeight: deco.strong ? FontWeight.w600 : null,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Den tron: xanh khi bat (hoac do neu la den canh bao), xam khi tat
class LedDot extends StatelessWidget {
  final bool? on;
  final bool warn;
  final double size;
  const LedDot({super.key, required this.on, this.warn = false, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = on == true ? (warn ? Vp.warn(cs) : Vp.ok(cs)) : cs.outlineVariant;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Ve mot truong theo kieu `t`. Kieu la hoac du lieu la -> chu chi doc, khong crash.
class FieldWidget extends StatelessWidget {
  final DeviceSession session;
  final int screen;
  final VphField field;
  final Map<String, dynamic> condValues;
  const FieldWidget({
    super.key,
    required this.session,
    required this.screen,
    required this.field,
    required this.condValues,
  });

  @override
  Widget build(BuildContext context) {
    final f = field;
    if (f.icon == null && f.desc == null) return _body(context);
    return FieldDeco(
      icon: f.icon,
      desc: f.desc,
      strong: !f.readOnly && !evalCond(f.enCond, condValues),
      child: Builder(builder: _body),
    );
  }

  Widget _body(BuildContext context) {
    final f = field;
    final c = fieldCtx(context, session, screen, f, condValues);
    final v = c.value;
    try {
      if (f.hint('note') && (f.type == 'bool' || f.type == 'text')) return NoteLine(field: f, value: v);
      switch (f.type) {
        case 'num':
          return NumField(c: c);
        case 'bool':
          return _bool(c);
        case 'text':
          return TextRow(c: c);
        case 'str':
          return StrField(c: c);
        case 'enum':
          return EnumField(c: c);
        case 'time':
          return TimeField(c: c);
        case 'date':
          return DateField(c: c);
        case 'days':
          return DaysField(c: c);
        case 'flags':
          return FlagsField(c: c);
        case 'act':
          return ActButton(c: c);
      }
    } catch (_) {
      // roi xuong hien chu chi doc
    }
    return FieldRow(label: '${f.id}: ${v ?? S.noData}');
  }

  Widget _bool(FieldCtx c) {
    final on = asBool(c.value);
    if (c.field.hint('led') || c.field.readOnly) {
      return FieldRow(
        label: c.field.label,
        busy: c.busy,
        draft: c.draft,
        trailing: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: LedDot(on: on, warn: c.field.hint('warn')),
        ),
      );
    }
    if (c.field.hint('btns')) {
      return FieldRow(
        label: c.field.label,
        busy: c.busy,
        draft: c.draft,
        below: Padding(padding: const EdgeInsets.only(top: 2, bottom: 4), child: OnOffButtons(c: c)),
      );
    }
    return FieldRow(
      label: c.field.label,
      busy: c.busy,
      draft: c.draft,
      trailing: Switch(value: on ?? false, onChanged: c.editable && !c.busy ? (nv) => c.onChanged(nv) : null),
    );
  }
}

/// Hai nut BẬT / TẮT thay cong tac (goi y btns)
class OnOffButtons extends StatelessWidget {
  final FieldCtx c;
  const OnOffButtons({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final on = asBool(c.value) ?? false;
    final can = c.editable && !c.busy;
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: can && !on ? () => c.onChanged(true) : null,
            icon: const Icon(Icons.power),
            label: const Text(S.onCaps),
          ),
        ),
        const SizedBox(width: Vp.gap),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: can && on ? () => c.onChanged(false) : null,
            icon: const Icon(Icons.power_off),
            label: const Text(S.offCaps),
          ),
        ),
      ],
    );
  }
}
