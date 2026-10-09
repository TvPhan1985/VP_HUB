import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Nhat ky chan doan (PLAN_HOAN_THIEN §H6): giu 500 dong gan nhat trong bo nho va ghi ra file
/// `vphub_log.txt` trong thu muc cua app (toi da 256 KB, day thi viet lai tu vong dem).
/// Ghi: ket noi, mat ket noi, MTU, loi, lenh ghi (id; khong ghi gia tri kieu `str`).
class DiagLog {
  static const int maxLines = 500;
  static const int maxBytes = 256 * 1024;
  static const String fileName = 'vphub_log.txt';

  static final DiagLog instance = DiagLog();

  final ListQueue<String> _lines = ListQueue<String>();
  final DateTime Function() _now;
  File? _file;
  int _size = 0;
  final List<String> _pending = [];
  Future<void> _tail = Future.value();

  DiagLog({DateTime Function()? now}) : _now = now ?? DateTime.now;

  /// Cac dong dang giu trong bo nho, cu truoc moi sau
  List<String> get lines => List.unmodifiable(_lines);

  File? get file => _file;

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String stamp(DateTime t) =>
      '${t.year}-${_two(t.month)}-${_two(t.day)} ${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

  void add(String msg) {
    final line = '${stamp(_now())} ${msg.replaceAll('\n', ' ')}';
    _lines.addLast(line);
    while (_lines.length > maxLines) {
      _lines.removeFirst();
    }
    if (_file != null) {
      _pending.add(line);
      _schedule();
    }
  }

  /// Gan file nhat ky. File cu qua lon thi bo, bat dau lai.
  Future<void> attach(File f) async {
    try {
      _size = await f.exists() ? await f.length() : 0;
      if (_size > maxBytes) {
        await f.writeAsString('');
        _size = 0;
      }
      _file = f;
    } catch (e) {
      debugPrint('VPHUB Khong mo duoc file nhat ky: $e');
    }
  }

  void _schedule() {
    _tail = _tail.then((_) => _write()).catchError((_) {});
  }

  Future<void> _write() async {
    final f = _file;
    if (f == null || _pending.isEmpty) return;
    final chunk = '${_pending.join('\n')}\n';
    _pending.clear();
    if (_size + chunk.length > maxBytes) {
      // Xoay vong: file day thi viet lai bang cac dong moi nhat trong vong dem, toi da nua gioi han
      final keep = <String>[];
      var n = 0;
      for (final line in _lines.toList().reversed) {
        if (n + line.length + 1 > maxBytes ~/ 2) break;
        keep.add(line);
        n += line.length + 1;
      }
      final all = keep.isEmpty ? '' : '${keep.reversed.join('\n')}\n';
      await f.writeAsString(all, flush: true);
      _size = all.length;
    } else {
      await f.writeAsString(chunk, mode: FileMode.append, flush: true);
      _size += chunk.length;
    }
  }

  /// Cho ghi xong moi dong dang doi (truoc khi xuat file)
  Future<void> flush() {
    _schedule();
    return _tail;
  }

  /// Xoa nhat ky (bo nho va file)
  Future<void> clear() async {
    _lines.clear();
    _pending.clear();
    await _tail;
    final f = _file;
    if (f != null) {
      try {
        await f.writeAsString('');
      } catch (_) {}
    }
    _size = 0;
  }
}

/// Ghi mot dong vao nhat ky chan doan (va console khi debug)
void logVph(String msg) {
  debugPrint('VPHUB $msg');
  DiagLog.instance.add(msg);
}

/// Gia tri de ghi vao nhat ky: khong ghi noi dung chuoi nguoi dung nhap (ten thiet bi, ...)
String logValue(String? type, dynamic v) => type == 'str' || v is String && type != 'enum' && type != 'time' && type != 'date'
    ? '<text>'
    : '$v';
