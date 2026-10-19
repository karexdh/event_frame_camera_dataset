"""
Reader for *_cd.bin / *_trigger.bin files written by evt3_raw_to_bin.exe.
Only depends on numpy.

    from read_evbin import read_evbin
    hdr, cd = read_evbin("recording_cd.bin")          # cd['x'], cd['y'], cd['p'], cd['t']
    hdr, trg = read_evbin("recording_trigger.bin")    # trg['p'], trg['id'], trg['t']
    hdr, part = read_evbin("recording_cd.bin", start=0, count=1_000_000)
    hdr, cd = read_evbin("recording_cd.bin", mmap=True)  # memory-mapped, for very large files
"""

import sys
import numpy as np

HEADER_DTYPE = np.dtype([
    ('magic', 'S8'),
    ('version', '<u2'),
    ('header_size', '<u2'),
    ('record_type', '<u2'),
    ('record_size', '<u2'),
    ('sensor_width', '<u2'),
    ('sensor_height', '<u2'),
    ('reserved0', '<u4'),
    ('num_records', '<u8'),
    ('time_offset_us', '<i8'),
    ('reserved', 'V24'),
])

RECORD_CD = 1
RECORD_TRIGGER = 2

CD_DTYPE = np.dtype([('x', '<u2'), ('y', '<u2'), ('p', 'u1'), ('t', '<i8')])          # 13 bytes
TRIGGER_DTYPE = np.dtype([('p', 'u1'), ('id', 'u1'), ('t', '<i8')])                 # 10 bytes


def read_header(path):
    """Returns the 64-byte file header as a dict."""
    raw = np.fromfile(path, dtype=HEADER_DTYPE, count=1)
    if raw.size != 1 or raw['magic'][0] != b'EVBIN001':
        raise ValueError(f'{path}: not an EVBIN file')
    return {name: raw[name][0].item() for name in HEADER_DTYPE.names if not name.startswith('reserved')}


def read_evbin(path, start=0, count=None, mmap=False):
    """
    Reads records [start, start + count) of an EVBIN file.
    Returns (header dict, numpy structured array).
    CD fields: x, y, p, t   Trigger fields: p, id, t   (t in microseconds)
    """
    hdr = read_header(path)
    dtype = {RECORD_CD: CD_DTYPE, RECORD_TRIGGER: TRIGGER_DTYPE}.get(hdr['record_type'])
    if dtype is None or dtype.itemsize != hdr['record_size']:
        raise ValueError(f"{path}: unsupported record type {hdr['record_type']}")

    n_total = hdr['num_records']
    start = min(max(int(start), 0), n_total)
    n = n_total - start if count is None else min(int(count), n_total - start)
    offset = hdr['header_size'] + start * dtype.itemsize

    if mmap:
        events = np.memmap(path, dtype=dtype, mode='r', offset=offset, shape=(n,))
    else:
        events = np.fromfile(path, dtype=dtype, count=n, offset=offset)
    return hdr, events


if __name__ == '__main__':
    for p in sys.argv[1:]:
        h, ev = read_evbin(p, count=5)
        print(p)
        print('  header:', h)
        print('  first records:', ev)
