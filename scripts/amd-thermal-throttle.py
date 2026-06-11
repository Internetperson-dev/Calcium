#!/usr/bin/env python3

import atexit
import glob
import os
import signal
import sys
import time

HIGH = 90000
LOW = 80000
SLEEP = 1
THROTTLED = False

tempfile = None
notifications_available = False


def find_cpu_temp():
    for hwmon in glob.glob("/sys/class/hwmon/hwmon*"):
        name_path = os.path.join(hwmon, "name")
        try:
            with open(name_path) as f:
                name = f.read().strip()
        except OSError:
            continue
        if name in ("coretemp", "k10temp", "cpu_temp"):
            temps = sorted(glob.glob(os.path.join(hwmon, "temp*_input")))
            if temps:
                return temps[0]
    return None


def cleanup():
    print("\nRestoring CPU governor and removing frequency cap...")

    for cpu in glob.glob("/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"):
        try:
            with open(cpu, "w") as f:
                f.write("schedutil")
        except OSError:
            pass

    max_freqs = glob.glob("/sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq")
    if max_freqs:
        with open(max_freqs[0]) as f:
            max_val = f.read().strip()
        for maxf in glob.glob("/sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq"):
            try:
                with open(maxf, "w") as f:
                    f.write(max_val)
            except OSError:
                pass

    print("CPU governor and frequency restored")


def notify(title, body):
    if not notifications_available:
        return
    try:
        import subprocess

        subprocess.run(
            [
                "gdbus",
                "call",
                "--session",
                "--dest",
                "org.freedesktop.Notifications",
                "--object-path",
                "/org/freedesktop/Notifications",
                "--method",
                "org.freedesktop.Notifications.Notify",
                "Terminal",
                "0",
                "",
                title,
                body,
                "[]",
                "{}",
                "5000",
            ],
            capture_output=True,
        )
    except OSError:
        pass


def avg_freq():
    freqs = glob.glob("/sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq")
    total = 0
    count = 0
    for path in freqs:
        try:
            with open(path) as f:
                total += int(f.read().strip())
                count += 1
        except (OSError, ValueError):
            pass
    return total // 1000 // count if count else 0


def load_avg():
    try:
        with open("/proc/loadavg") as f:
            parts = f.read().split()
            return int(float(parts[0]) * 100)
    except (OSError, IndexError, ValueError):
        return 0


def main():
    global THROTTLED, tempfile, notifications_available

    tempfile = find_cpu_temp()
    if tempfile is None:
        print("CPU temperature sensor not found!", file=sys.stderr)
        sys.exit(1)

    print(f"Monitoring CPU temp at {tempfile}")

    atexit.register(cleanup)
    signal.signal(signal.SIGINT, lambda s, f: sys.exit(0))
    signal.signal(signal.SIGTERM, lambda s, f: sys.exit(0))

    notifications_available = os.system("gdbus --version >/dev/null 2>&1") == 0

    while True:
        try:
            with open(tempfile) as f:
                temp_str = f.read().strip()
        except OSError:
            time.sleep(SLEEP)
            continue

        try:
            temp = int(temp_str)
        except ValueError:
            time.sleep(SLEEP)
            continue

        if temp >= HIGH and not THROTTLED:
            print(f"\nTHERMAL ALERT: {temp / 1000:.1f}°C — throttling CPU")
            for cpu in glob.glob(
                "/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
            ):
                try:
                    with open(cpu, "w") as f:
                        f.write("powersave")
                except OSError:
                    pass
            for maxf in glob.glob(
                "/sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq"
            ):
                try:
                    with open(maxf, "w") as f:
                        f.write("500000")
                except OSError:
                    pass
            THROTTLED = True
            notify(
                "Slowing down...",
                "Your computer is running too hot. It will now slow down to prevent damage.",
            )

        if temp <= LOW and THROTTLED:
            print(f"\nTHERMAL NORMAL: {temp / 1000:.1f}°C — restoring CPU")
            for cpu in glob.glob(
                "/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor"
            ):
                try:
                    with open(cpu, "w") as f:
                        f.write("schedutil")
                except OSError:
                    pass
            max_freqs = glob.glob(
                "/sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq"
            )
            if max_freqs:
                with open(max_freqs[0]) as f:
                    max_val = f.read().strip()
                for maxf in glob.glob(
                    "/sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq"
                ):
                    try:
                        with open(maxf, "w") as f:
                            f.write(max_val)
                    except OSError:
                        pass
            THROTTLED = False

        af = avg_freq()
        ld = load_avg()
        print(
            f"\rTemp: {temp / 1000:.1f} °C | Avg Freq: {af} MHz | Load: {ld}% | THROTTLED: {int(THROTTLED)}",
            end="",
        )

        time.sleep(SLEEP)


if __name__ == "__main__":
    main()
