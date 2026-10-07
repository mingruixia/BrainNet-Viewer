"""Small macOS hardware query used by the desktop status strip."""
import subprocess


def mac_hardware():
    """Return CPU brand and physical RAM bytes, independently falling back.

    Total physical RAM is not currently available/free RAM. Failed or restricted
    OS queries leave the corresponding field unknown rather than guessing.
    """
    def read(key):
        try:
            return subprocess.check_output(
                ["/usr/sbin/sysctl", "-n", key], text=True,
                stderr=subprocess.DEVNULL, timeout=1,
            ).strip()
        except (OSError, subprocess.SubprocessError):
            return ""

    brand = read("machdep.cpu.brand_string")
    try:
        total = int(read("hw.memsize"))
    except ValueError:
        total = 0
    return brand, total if total > 0 else None
