"""Operating-system hardware queries for the desktop status strip."""
import subprocess
from pathlib import Path
import re


def linux_hardware(proc_root=Path('/proc')):
    """Read host CPU topology and physical RAM; never substitute process RAM.

    Missing topology or MemAvailable is left unknown. MemFree alone excludes
    reclaimable cache and must not be labelled available memory.
    """
    def read(name):
        try:
            return (proc_root / name).read_text(encoding='utf-8', errors='replace')
        except OSError:
            return ''
    records = [dict(re.findall(r'^([^:\n]+)\s*:\s*(.*)$', block, re.M))
               for block in re.split(r'\n\s*\n', read('cpuinfo')) if block.strip()]
    records = [{key.strip(): value.strip() for key, value in row.items()} for row in records]
    brand = next((row[key] for row in records for key in ('model name', 'Hardware')
                  if row.get(key)), '')
    processors = [row for row in records if 'processor' in row and row['processor'].isdigit()]
    pairs = {(row['physical id'], row['core id']) for row in processors
             if 'physical id' in row and 'core id' in row}
    physical = len(pairs) if processors and all('physical id' in row and 'core id' in row for row in processors) else None
    memory = {key: int(value) * 1024 for key, value in
              re.findall(r'^(MemTotal|MemAvailable):\s+(\d+)\s+kB\s*$', read('meminfo'), re.M)}
    total = memory.get('MemTotal') or None
    available = memory.get('MemAvailable')
    if total is None or available is None or not 0 <= available <= total:
        available = None
    return brand, len(processors) or None, physical, total, available


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
