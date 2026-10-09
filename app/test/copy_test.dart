import 'package:flutter_test/flutter_test.dart';
import 'package:vphub/core/known_devices.dart';
import 'package:vphub/core/model/vph_schema.dart';
import 'package:vphub/core/schema_cache.dart';
import 'package:vphub/ui/render/flags_field.dart';
import 'package:vphub/ui/render/num_field.dart';

/// Cac quy tac chu trong docs/COPY_STYLE.md ma code phai giu
void main() {
  test('bit bao dong khong co nhan: dem tu 1 ("Alarm 4"), khong hien chu "bit"', () {
    final f = VphField.fromJson({'id': 'al', 't': 'flags', 'opt': ['Sensor lost']});
    expect(activeFlags(f, 1 | 8), ['Sensor lost', 'Alarm 4']);
  });

  test('thoi luong: don vi sau luon 2 chu so', () {
    expect(durText(7512), '2 h 05 min');
    expect(durText(312), '5 min 12 s');
    expect(durText(65), '1 min 05 s');
    expect(durText(3 * 86400 + 4 * 3600), '3 d 04 h');
  });

  test('xoa thiet bi roi hoan tac: ve dung vi tri cu; doi ten chi trong app', () async {
    final k = KnownDevices(MemoryStore());
    for (final id in ['c', 'b', 'a']) {
      await k.remember(KnownDevice(id: id, name: 'Dev $id'));
    }
    expect(k.list().map((d) => d.id), ['a', 'b', 'c']);
    final b = k.list()[1];
    await k.forget('b');
    expect(k.list().map((d) => d.id), ['a', 'c']);
    await k.insertAt(1, b);
    expect(k.list().map((d) => d.id), ['a', 'b', 'c']);
    await k.rename('c', 'Greenhouse pump');
    final c = k.list().last;
    expect(c.name, 'Greenhouse pump');
    expect(c.alias, isTrue);
    expect(KnownDevices(k.store).list().last.alias, isTrue);
  });
}
