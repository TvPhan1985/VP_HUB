import 'package:flutter/material.dart';

import '../../core/cond.dart';
import '../../core/device_session.dart';
import '../../core/model/vph_schema.dart';
import '../../core/model/vph_value.dart';
import '../../l10n/strings_vi.dart';
import 'act_button.dart';
import 'date_field.dart';
import 'days_field.dart';
import 'enum_field.dart';
import 'flags_field.dart';
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
    final color = on == true ? (warn ? cs.error : Colors.green) : cs.outlineVariant;
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

  Future<void> _change(BuildContext context, dynamic v) async {
    final c = field.confirm;
    // Cong tac chi hoi lai khi bat (vd dot lo), tat thi lam ngay
    final ask = c != null && (field.type != 'bool' || v == true);
    if (ask && !await confirmDialog(context, c)) return;
    await session.edit(screen, field, v);
  }

  @override
  Widget build(BuildContext context) {
    final f = field;
    final v = session.valueOf(screen, f.id);
    final c = FieldCtx(
      field: f,
      value: v,
      editable: session.ready && !session.saving && !f.readOnly && evalCond(f.enCond, condValues),
      busy: session.busy.contains(f.id),
      draft: session.isDraft(screen, f.id),
      onChanged: (nv) => _change(context, nv),
    );
    try {
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
    return FieldRow(
      label: c.field.label,
      busy: c.busy,
      draft: c.draft,
      trailing: Switch(value: on ?? false, onChanged: c.editable && !c.busy ? (nv) => c.onChanged(nv) : null),
    );
  }
}
