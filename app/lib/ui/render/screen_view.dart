import 'package:flutter/material.dart';

import '../../core/app_settings.dart';
import '../../core/cond.dart';
import '../../core/device_session.dart';
import '../../core/model/vph_schema.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import 'alarm_card.dart';
import 'field_widget.dart';
import 'hero_card.dart';
import 'note_line.dart';
import 'num_field.dart';
import 'tile_card.dart';
import 'trend_chart.dart';

/// Noi dung mot tab, ve hoan toan tu schema (SPEC §4)
class ScreenView extends StatelessWidget {
  final DeviceSession session;
  final int index;
  const ScreenView({super.key, required this.session, required this.index});

  Widget _card(BuildContext context, String? title, List<Widget> children) => Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(height: 4),
            ...children,
            const SizedBox(height: 4),
          ],
        ),
      );

  /// Schema khong co goi y nao: o man dau, toi da 2 so chi doc dau tien tu hien dang tile
  Set<String> _autoTiles(VphScreen screen) {
    if (index != 0 || screen.fields.any((f) => f.hints.isNotEmpty)) return const {};
    return {
      for (final f in screen.fields.where((f) => f.type == 'num' && f.readOnly).take(2)) f.id,
    };
  }

  static bool _isAlarm(VphField f) => f.hint('alarm') && (f.type == 'flags' || f.type == 'bool');

  @override
  Widget build(BuildContext context) {
    final screen = session.screens[index];
    if (screen.error != null) {
      final cs = Theme.of(context).colorScheme;
      return ListView(
        padding: const EdgeInsets.all(Vp.pad),
        children: [
          Card(
            color: cs.errorContainer,
            child: ListTile(
              leading: Icon(Icons.error_outline, color: cs.onErrorContainer),
              title: Text(S.schemaError, style: TextStyle(color: cs.onErrorContainer)),
              subtitle: Text(screen.error!, style: TextStyle(color: cs.onErrorContainer)),
            ),
          ),
        ],
      );
    }

    // Dieu kien if/en tinh tren gia tri thiet bi + gia tri dang sua cua man nay
    final cond = <String, dynamic>{...session.values, ...?session.drafts[index]};
    Widget fw(VphField f) => FieldWidget(session: session, screen: index, field: f, condValues: cond);
    Widget trend(VphField f) => TrendChart(field: f, points: session.trends[f.id] ?? const []);
    FieldCtx ctx(VphField f) => fieldCtx(context, session, index, f, cond);

    final auto = _autoTiles(screen);
    bool isBig(VphField f) => f.hint('big') && f.type == 'num';
    bool isTile(VphField f) =>
        (f.hint('tile') || auto.contains(f.id)) && (f.type == 'num' || f.type == 'text' || f.type == 'enum');
    bool isMini(VphField f) => f.hint('mini') && (f.type == 'num' || f.type == 'text');
    bool isNote(VphField f) => f.hint('note') && (f.type == 'bool' || f.type == 'text');
    bool isHero(VphField f) => f.hint('hero') && f.type == 'bool';

    final items = <Widget>[];
    // Truong adv chi hien o che do Technician (van dung duoc trong if/en, sub, hdr)
    final tech = SettingsScope.technician(context);
    bool show(VphField f) => (tech || !f.adv) && evalCond(f.ifCond, cond);
    final visible = [for (final f in screen.fields) if (show(f)) f];

    // The so lon dua len dau tab
    for (final f in visible.where(isBig)) {
      items.add(BigValueCard(field: f, value: session.valueOf(index, f.id)));
      if (f.hint('trend')) items.add(_card(context, null, [trend(f)]));
    }

    // Cac truong con lai, dung thu tu schema. Truong thuong cung nhom `g` lien nhau gom vao mot the.
    String? group;
    var rows = <Widget>[];
    var open = false;
    void flush() {
      if (open && rows.isNotEmpty) items.add(_card(context, group, rows));
      rows = <Widget>[];
      open = false;
    }

    // Lay cum truong lien nhau cung thoa [test], bat dau tu i
    List<VphField> run(int i, bool Function(VphField) test) {
      var j = i;
      while (j < visible.length && test(visible[j])) {
        j++;
      }
      return visible.sublist(i, j);
    }

    for (var i = 0; i < visible.length;) {
      final f = visible[i];
      if (isBig(f)) {
        i++;
      } else if (isNote(f)) {
        flush();
        items.add(NoteLine(field: f, value: session.valueOf(index, f.id)));
        i++;
      } else if (isTile(f)) {
        flush();
        final fs = run(i, isTile);
        items.add(TileGroup(key: ValueKey('tile-${f.id}'), session: session, screen: index, fields: fs));
        i += fs.length;
      } else if (isMini(f)) {
        flush();
        final fs = run(i, isMini);
        items.add(MiniStrip(session: session, screen: index, fields: fs));
        i += fs.length;
      } else if (isHero(f)) {
        flush();
        final sf = f.sub == null ? null : session.fieldById(f.sub!);
        items.add(HeroCard(
          c: ctx(f),
          subText: f.sub == null ? null : '${sf?.label ?? f.sub}: ${displayValue(sf, cond[f.sub])}',
          locked: !f.readOnly && !evalCond(f.enCond, cond),
        ));
        i++;
      } else if (_isAlarm(f)) {
        flush();
        // Truong lien sau, cung nhom: nut lenh, den, dong chu -> dat vao trong the bao dong
        final extras = f.group == null
            ? const <VphField>[]
            : run(
                i + 1,
                (e) =>
                    e.group == f.group &&
                    !_isAlarm(e) &&
                    (e.type == 'act' || e.type == 'bool' || e.type == 'text'),
              );
        items.add(AlarmCard(c: ctx(f), extras: [for (final e in extras) ctx(e)]));
        i += 1 + extras.length;
      } else {
        if (!open || f.group != group) {
          flush();
          group = f.group;
          open = true;
        }
        rows.add(fw(f));
        if (f.hint('trend') && f.type == 'num') rows.add(trend(f));
        i++;
      }
    }
    flush();

    // Khoi lap: moi lan lap mot the; `cnt` gioi han so the theo gia tri mot truong
    final rep = screen.rep;
    if (rep != null) {
      var shown = screen.repGroups.length;
      final cnt = rep.cnt == null ? null : cond[rep.cnt];
      if (cnt is num) shown = cnt.toInt().clamp(0, shown);
      for (final g in screen.repGroups.take(shown)) {
        final fs = [for (final f in g.fields) if (show(f)) fw(f)];
        if (fs.isNotEmpty) items.add(_card(context, '${rep.label ?? S.repDefault} ${g.index}', fs));
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(Vp.pad, Vp.gap, Vp.pad, 24),
      children: items,
    );
  }
}
