import 'dart:async';
import 'dart:convert';

import 'package:vphub/core/transport/gatt_link.dart';
import 'package:vphub/core/transport/uuids.dart';

/// Characteristic gia lap de test transport khong can BLE
class FakeGattLink implements GattLink {
  final Map<String, List<int> Function()> readers = {};
  final Map<String, void Function(List<int> data)> writers = {};
  final Map<String, void Function(List<int> data)> subs = {};
  final List<(String, List<int>)> writeLog = [];
  final List<String> readLog = [];
  final StreamController<void> lostCtl = StreamController.broadcast();
  bool disconnected = false;

  @override
  String name;

  @override
  List<String> services;

  @override
  int mtu;

  FakeGattLink({this.name = 'FAKE', this.services = const [], this.mtu = 247});

  @override
  String get deviceId => '00:11:22:33:44:55';

  @override
  Stream<void> get lost => lostCtl.stream;

  @override
  Future<void> connect() async {}

  @override
  Future<List<int>> read(String chr) async {
    readLog.add(chr);
    final r = readers[chr];
    if (r == null) throw StateError('khong doc duoc $chr');
    return r();
  }

  @override
  Future<void> write(String chr, List<int> data) async {
    writeLog.add((chr, List.of(data)));
    writers[chr]?.call(data);
  }

  @override
  Future<void> subscribe(String chr, void Function(List<int> data) onData) async {
    subs[chr] = onData;
  }

  @override
  Future<int?> readRssi() async => -60;

  @override
  Future<void> disconnect() async {
    disconnected = true;
  }

  void notify(String chr, String text) => subs[chr]?.call(utf8.encode(text));

  /// Cac chuoi JSON da ghi vao mot characteristic
  List<String> written(String chr) => [for (final w in writeLog) if (w.$1 == chr) utf8.decode(w.$2)];
}

/// Thiet bi VPH v1 gia: INFO, schema cat trang 480 byte, VALUES theo man dang chon, RESULT co q
class FakeVphDevice {
  final FakeGattLink link = FakeGattLink(services: [kVphService]);
  Map<String, dynamic> info;
  List<String> schemas;
  List<Map<String, dynamic>> values;
  int screen = 0, page = 0;
  bool silent = false;

  /// Tra null = ok, chuoi = loi
  String? Function(Map<String, dynamic> cmd) onWrite = (_) => null;
  final List<Map<String, dynamic>> commands = [];

  FakeVphDevice({required this.info, required this.schemas, List<Map<String, dynamic>>? values})
      : values = values ?? [for (final _ in schemas) <String, dynamic>{}] {
    link.readers[kVphInfo] = () => utf8.encode(jsonEncode(info));
    link.readers[kVphSchema] = () {
      if (screen >= schemas.length) return utf8.encode('{}');
      final all = utf8.encode(schemas[screen]);
      final from = page * 480;
      if (from >= all.length) return <int>[];
      return all.sublist(from, from + 480 > all.length ? all.length : from + 480);
    };
    link.readers[kVphValues] =
        () => utf8.encode(jsonEncode(screen < this.values.length ? this.values[screen] : {}));
    link.writers[kVphSelect] = (d) {
      screen = d[0];
      page = d.length > 1 ? d[1] : 0;
    };
    link.writers[kVphWrite] = (d) {
      final cmd = jsonDecode(utf8.decode(d)) as Map<String, dynamic>;
      commands.add(cmd);
      if (silent) return;
      final err = onWrite(cmd);
      scheduleMicrotask(() => link.notify(
          kVphResult, jsonEncode(err == null ? {'q': cmd['q'], 'ok': 1} : {'q': cmd['q'], 'ok': 0, 'err': err})));
    };
  }
}
