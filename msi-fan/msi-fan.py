#!/usr/bin/env python3
"""Standalone MS-14K2 / 14K2EMS1.110 fan control. Ctrl+C restores stock."""
import contextlib
import fcntl
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

CPU = (0x72, [0, 36, 40, 50, 62, 80, 96])
GPU = (0x8a, [0, 36, 42, 50, 62, 80, 96])
TARGET = [30, 42, 48, 58, 70, 90, 100]
TEMPS = {0x6a: bytes([57, 62, 70, 77, 83, 90]),
         0x82: bytes([50, 60, 65, 70, 78, 83])}
DEBUG = Path('/sys/kernel/debug')


def run(*args):
    subprocess.run(args, check=True)


@contextlib.contextmanager
def access():
    loaded = mounted = False
    fd = None
    try:
        if not Path('/sys/module/ec_sys').exists():
            run('modprobe', 'ec_sys', 'write_support=1')
            loaded = True
        if Path('/sys/module/ec_sys/parameters/write_support').read_text().strip() != 'Y':
            raise RuntimeError('Existing ec_sys is read-only; refusing to change it')
        if not os.path.ismount(DEBUG):
            run('mount', '-t', 'debugfs', 'debugfs', str(DEBUG))
            mounted = True
        fd = os.open(DEBUG / 'ec/ec0/io', os.O_RDWR)
        yield fd
    finally:
        if fd is not None:
            os.close(fd)
        try:
            if mounted:
                run('umount', str(DEBUG))
        finally:
            if loaded:
                # Don't fail the service after a successful restore just because
                # unload races a reboot / missing modules tree.
                subprocess.run(['modprobe', '-r', 'ec_sys'], check=False)


def read(fd, addr, count=1):
    data = os.pread(fd, count, addr)
    if len(data) != count:
        raise RuntimeError('Short EC read')
    return data


def write(fd, addr, value):
    if os.pwrite(fd, bytes([value]), addr) != 1 or read(fd, addr)[0] != value:
        raise RuntimeError(f'EC write/readback mismatch at {addr:#x}')


def stop(signum, frame):
    raise KeyboardInterrupt


def main():
    if os.geteuid() != 0:
        raise RuntimeError('Run: sudo python3 ./msi-fan.py')
    if Path('/sys/class/dmi/id/board_name').read_text().strip() != 'MS-14K2':
        raise RuntimeError('Unsupported motherboard')
    with open('/run/lock/msi-fan.lock', 'a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError('Another controller is running. Stop it first: sudo systemctl stop msi-fan') from None
        signal.signal(signal.SIGTERM, stop)
        signal.signal(signal.SIGHUP, stop)
        with access() as fd:
            def verify_map():
                if read(fd, 0xa0, 12) != b'14K2EMS1.110':
                    raise RuntimeError('Unsupported EC firmware; refusing writes')
                for addr, expected in TEMPS.items():
                    if read(fd, addr, 6) != expected:
                        raise RuntimeError('Temperature thresholds changed; refusing control')

            verify_map()
            if read(fd, 0xd4)[0] != 0x0d:
                raise RuntimeError('Expected automatic mode at startup')
            for base, stock in (CPU, GPU):
                if list(read(fd, base, 7)) != stock:
                    raise RuntimeError('Expected stock curve at startup')
            original = {a: read(fd, a)[0] for a in
                        list(range(0x72, 0x79)) + list(range(0x8a, 0x91)) + [0xd4]}
            changed = set()

            def apply():
                for base, _ in (CPU, GPU):
                    for i, value in enumerate(TARGET):
                        addr = base + i
                        changed.add(addr)
                        write(fd, addr, value)
                changed.add(0xd4)
                write(fd, 0xd4, 0x8d)

            try:
                apply()
                print('Fan curves:', TARGET, '| Ctrl+C restores stock.', flush=True)
                last_log = 0
                while True:
                    verify_map()
                    mode = read(fd, 0xd4)[0]
                    curves = [list(read(fd, base, 7)) for base, _ in (CPU, GPU)]
                    if mode == 0x0d and curves == [CPU[1], GPU[1]]:
                        apply()
                    elif mode != 0x8d or curves != [TARGET, TARGET]:
                        raise RuntimeError('External fan setting change; stopping')
                    temp = read(fd, 0x68)[0]
                    if temp >= 85:
                        raise RuntimeError('85 C safety fallback; restoring automatic mode')
                    if time.monotonic() - last_log >= 60:
                        print(f'CPU {temp} C | fan1 {read(fd, 0x71)[0]} | fan2 {read(fd, 0x89)[0]}', flush=True)
                        last_log = time.monotonic()
                    time.sleep(5)
            except KeyboardInterrupt:
                print('Stopping...', flush=True)
            finally:
                # A second stop signal must not interrupt stock restoration.
                for sig in (signal.SIGINT, signal.SIGTERM, signal.SIGHUP):
                    signal.signal(sig, signal.SIG_IGN)
                if read(fd, 0xa0, 12) != b'14K2EMS1.110':
                    raise RuntimeError('Firmware changed; cannot safely restore')
                errors = []
                for addr in sorted(changed):
                    try:
                        write(fd, addr, original[addr])
                    except Exception as e:
                        errors.append(str(e))
                if errors:
                    raise RuntimeError('RESTORE FAILED: ' + '; '.join(errors))
                print('Stock curves and automatic mode restored and verified.', flush=True)


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print('ERROR:', e, file=sys.stderr, flush=True)
        sys.exit(1)
