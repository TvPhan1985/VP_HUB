import 'dart:async';

/// Lop mong che thu vien BLE, de transport test duoc bang characteristic gia lap.
/// UUID la chuoi 128 bit chu thuong.
abstract class GattLink {
  String get deviceId;

  /// Ten quang ba (co the rong)
  String get name;

  /// MTU da thuong luong (0 neu chua biet)
  int get mtu;

  /// UUID cac dich vu tim thay sau khi ket noi
  List<String> get services;

  /// Ket noi, xin MTU, tim dich vu
  Future<void> connect();

  Future<List<int>> read(String chr);

  /// Ghi co phan hoi
  Future<void> write(String chr, List<int> data);

  /// Dang ky notify; [onData] duoc gan truoc khi bat notify de khong sot goi
  Future<void> subscribe(String chr, void Function(List<int> data) onData);

  /// Phat khi mat ket noi ngoai y muon
  Stream<void> get lost;

  /// Cuong do song hien tai (dBm), null neu khong doc duoc
  Future<int?> readRssi();

  Future<void> disconnect();
}

/// Hang doi chay tuan tu: moi thao tac BLE di qua day, khong goi chong (SPEC §7)
class OpQueue {
  Future<void> _tail = Future.value();

  Future<T> run<T>(Future<T> Function() action) {
    final r = _tail.then((_) => action());
    _tail = r.then((_) {}, onError: (_) {});
    return r;
  }
}
