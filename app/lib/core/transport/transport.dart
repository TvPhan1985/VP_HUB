import 'dart:async';

import '../model/vph_info.dart';
import '../model/vph_schema.dart';
import '../model/vph_value.dart';

/// So lieu de hien o man Thong tin thiet bi (SPEC §5)
class TransportStats {
  int mtu = 0;
  int maxValuesLen = 0;
  int valuesCount = 0;
  int badPackets = 0;
  bool schemaFromCache = false;
}

/// Giao dien chung cho moi giao thuc (VPH that, adapter doi cu, demo).
/// UI chi lam viec voi lop nay, khong biet ben duoi la transport nao.
abstract class DeviceTransport {
  /// Ma giao thuc that ('VPH v1', 'demo', 'kiln_v0', 'c3relay_v1'); UI doi sang chu o man Device info
  String get protoId;

  /// true neu la adapter cho thiet bi doi cu
  bool get legacy;

  TransportStats get stats;

  /// Doc INFO (duong truyen da ket noi san)
  Future<VphInfo> open();

  /// Doc schema (hoac lay tu cache). [refresh] = bo cache, doc lai tu thiet bi
  Future<List<VphScreen>> loadScreens({bool refresh = false});

  /// Dang ky notify, gui gio neu thiet bi can
  Future<void> start();

  /// VALUES da giai ma; moi goi la mot phan, noi nhan tu gop
  Stream<Map<String, dynamic>> get values;

  /// Phat khi mat ket noi ngoai y muon
  Stream<void> get lost;

  Future<void> select(int screen);

  Future<VphResult> write(String id, dynamic v);

  Future<VphResult> writeBatch(Map<String, dynamic> set);

  Future<void> close();
}
