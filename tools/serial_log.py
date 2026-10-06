"""Doc log serial co gioi han thoi gian (thay cho idf.py monitor).

Vi du:
  tools/.venv/Scripts/python tools/serial_log.py --port COM5 --seconds 20
  tools/.venv/Scripts/python tools/serial_log.py --port COM5 --seconds 60 --reset --expect "Tests 0 Failures"
Ma thoat: 0 neu thay chuoi --expect (hoac khong dat --expect), 2 neu khong thay, 1 neu loi cong.
"""
import argparse
import sys
import time

import serial


def reset_chip(ser):
    # USB-Serial-JTAG cua C3: RTS=EN, DTR=IO9. Giu DTR=0 de khoi dong binh thuong.
    ser.dtr = False
    ser.rts = True
    time.sleep(0.1)
    ser.rts = False
    ser.dtr = False


def open_port(port, baud):
    # Ha DTR/RTS truoc khi mo de khong reset chip (RTS noi EN tren USB-Serial-JTAG)
    s = serial.Serial()
    s.port = port
    s.baudrate = baud
    s.timeout = 0.2
    s.dtr = False
    s.rts = False
    s.open()
    return s


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", default="COM5")
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--seconds", type=float, default=10)
    ap.add_argument("--expect", action="append", default=[],
                    help="chuoi can thay; dung som khi thay het (co the lap lai)")
    ap.add_argument("--stop-on", default=None, help="dung som khi gap chuoi nay")
    ap.add_argument("--reset", action="store_true", help="reset chip truoc khi doc")
    ap.add_argument("--out", default=None, help="ghi log ra file")
    a = ap.parse_args()

    ser = None
    t_open = time.time()
    while ser is None:
        try:
            ser = open_port(a.port, a.baud)
        except serial.SerialException as e:
            if time.time() - t_open > 5:
                print(f"[serial_log] khong mo duoc {a.port}: {e}", file=sys.stderr)
                return 1
            time.sleep(0.3)
    if a.reset:
        reset_chip(ser)

    out = open(a.out, "w", encoding="utf-8") if a.out else None
    pending = list(a.expect)
    buf = b""
    t_end = time.time() + a.seconds
    try:
        while time.time() < t_end:
            try:
                data = ser.read(1024)
            except serial.SerialException:
                # Chip reset lam mat cong USB tam thoi, mo lai
                ser.close()
                time.sleep(0.5)
                try:
                    ser = open_port(a.port, a.baud)
                except serial.SerialException:
                    pass
                continue
            if not data:
                continue
            buf += data
            while b"\n" in buf:
                line, buf = buf.split(b"\n", 1)
                s = line.decode("utf-8", errors="replace").rstrip("\r")
                print(s, flush=True)
                if out:
                    out.write(s + "\n")
                pending = [p for p in pending if p not in s]
                if a.expect and not pending:
                    return 0
                if a.stop_on and a.stop_on in s:
                    return 0 if not pending else 2
    finally:
        if buf:
            print(buf.decode("utf-8", errors="replace"))
        ser.close()
        if out:
            out.close()
    if pending:
        print(f"[serial_log] KHONG thay: {pending}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
