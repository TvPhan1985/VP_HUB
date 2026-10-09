import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Chu cua app: ban goc lib/l10n/app_en.arb, ban dich app_vi.arb (PLAN_HOAN_THIEN §H4)
void main() {
  Map<String, dynamic> arb(String name) =>
      jsonDecode(File('lib/l10n/$name').readAsStringSync()) as Map<String, dynamic>;

  test('moi khoa cua app_en.arb deu co ban dich trong app_vi.arb, va nguoc lai', () {
    Set<String> keys(Map<String, dynamic> m) => {for (final k in m.keys) if (!k.startsWith('@')) k};
    final en = keys(arb('app_en.arb')), vi = keys(arb('app_vi.arb'));
    expect(en.difference(vi), isEmpty, reason: 'thieu ban tieng Viet');
    expect(vi.difference(en), isEmpty, reason: 'khoa thua trong ban tieng Viet');
  });

  test('ban dich giu du cac tham so {ten} cua ban goc', () {
    final en = arb('app_en.arb'), vi = arb('app_vi.arb');
    final ph = RegExp(r'\{(\w+)[,}]');
    for (final k in en.keys.where((k) => !k.startsWith('@'))) {
      Set<String> names(String s) => {for (final m in ph.allMatches(s)) m.group(1)!};
      expect(names(vi[k] as String), names(en[k] as String), reason: k);
    }
  });

  test('chu tieng Anh theo COPY_STYLE: khong dau cham than, khong "Please", khong thuat ngu noi bo o cau loi', () {
    final en = arb('app_en.arb');
    for (final e in en.entries.where((e) => !e.key.startsWith('@'))) {
      final s = e.value as String;
      expect(s.contains('!'), isFalse, reason: e.key);
      expect(s.toLowerCase().contains('please'), isFalse, reason: e.key);
      expect(s.contains('...'), isFalse, reason: '${e.key}: dung dau ba cham "…"');
      if (e.key.startsWith('err') && e.key != 'errorDetails') {
        for (final w in ['schema', 'VPH', 'MTU', 'packet', 'GATT', 'UUID', 'legacy', 'adapter']) {
          expect(s.contains(w), isFalse, reason: '${e.key} co thuat ngu "$w"');
        }
      }
    }
  });

  test('lib/ui khong con chuoi hien thi viet cung', () {
    // Chu dua thang vao widget: Text('...'), tooltip: '...', labelText: '...' ...
    final hard = RegExp(
        r'''(?:\bText\(\s*|(?:tooltip|message|labelText|hintText|helperText|errorText|semanticLabel)\s*:\s*)(?:const\s+)?(['"])((?:(?!\1).)*[A-Za-zÀ-ỹ]{2}(?:(?!\1).)*)\1''');
    final bad = <String>[];
    for (final f in Directory('lib/ui').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//')) continue;
        for (final m in hard.allMatches(line)) {
          final lit = m.group(2)!;
          // Chuoi chi gom bien noi suy ("$a · $b") thi khong phai chu viet cung
          final plain = lit.replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '');
          if (RegExp(r'[A-Za-zÀ-ỹ]{2}').hasMatch(plain)) bad.add('${f.path}:${i + 1}: $lit');
        }
      }
    }
    expect(bad, isEmpty, reason: 'dua cac chuoi nay vao app_en.arb / app_vi.arb:\n${bad.join('\n')}');
  });
}
