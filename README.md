# Event–Frame Hybrid Camera OOK Dataset for Free-Space and Underwater Optical Communication

## 1. Dataset overview

This dataset presents multiple on-off-keyed (OOK) optical signals that are transmitted by a single LED and captured by a frame-event camera with a 50:50 light split. Collected under various bit rates, channel conditions and distances, the dataset can be used to understand and model the characteristics and responsivity of event-based cameras; it also offers potential for developing applications that use data from both frame and event cameras. The dataset is suitable for exploring event-based or event-frame hybrid optical communication applications.

The dataset is available in the following channel settings:

- **Free-space optical (FSO)**: LED and cameras in air, with a line-of-sight link at 0.5 m and 1 m distance.
- **Underwater**: the same setup, but with a 1 m light path through water.

Each condition was recorded with the room light on (`On`) and off (`Off`).


## 2. Dataset file structure

```
Dataset/
├─ README.md
├─ reference_bits.mat          reference PRBS sequences (ground-truth bits)
├─ readers/                    example dataloader code
├─ event_frame_FSO/            36 recordings
│   └─ FSO_<distance>_<bitrate>_<On|Off>/
└─ event_frame_Underwater/     14 recordings
    └─ Underwater_1m_<bitrate>_<On|Off>/
```

Folder names: `<channel>_<distance>_<bit rate>_<room light>`, with `0_5m` = 0.5 m.
For example, `FSO_0_5m_10kbps_On` contains the data with a bit rate of 10 kbps collected over the 0.5 m FSO link with the room light on.

Each recording folder contains:

| File | Content |
|---|---|
| `<name>_cd.bin` | Event-camera CD events (x, y, polarity, timestamp) |
| `<name>_trigger.bin` | Frame-camera sync pulses that mark the beginning of each frame |
| `<name>.mp4` | Frame-camera video |
| `<name>_lost-cam-frame.txt` | Frames dropped by the frame camera (only if any were lost) |

## 3. Data acquisition setup

**Signal generation.** All transmitted bits are generated as pseudorandom binary sequences (PRBS) of various lengths. After a one-off generation process, the generated bit patterns are stored in `reference_bits.mat` and are used throughout the data collection. 

To achieve different bit rates with the same source sequence, every bit is oversampled with 16 samples per symbol (SPS) and transmitted at various sample rates (Sa/s). For example, a sample rate of 160 kSa/s yields a bit rate of Rb = Fs / SPS = 160k / 16 = 10 kbps.

**Transmitter.** A Siglent SDG6052X waveform generator is used to generate the source bit sequences and convert them into voltage outputs with V_offset = 2.5 V and V_pp = 5 V. The output voltage passes through a current-limiting resistor connected in series with the LED light source. A 3 W warm white LED (SJ-3W-WW, iPixelLED) is used as the light source.

**Receiver.** A SilkyEvCam BothView C-mount camera is used as the receiver. This camera is a hybrid vision camera that contains a built-in, synchronized frame camera and event camera. With a 50:50 light split ratio, the camera distributes the captured light evenly between both cameras. The frame camera runs at ~59.77 fps, while the event camera is specified to have 1 µs level resolution. The frame camera generates frame-start sync pulses, which are recorded by the event camera as external triggers (`_trigger.bin`). 

When frames are lost, the relevant information is recorded in `_lost-cam-frame.txt` (the video contains only the frames that were received). In this case, `_trigger.bin` still records the frame-start sync signal, but the corresponding frame cannot be recovered from the `*.mp4` file returned by the frame camera. The total numbers of frames captured and lost are recorded in the `_result.txt` file under the same folder.

**Timing notes.** The transmitter and the receiver are started manually and are not synchronized, meaning that the start of a frame might not be aligned with the beginning of a bit. This setup is used on purpose to emulate a practical optical communication scenario that poses challenges for conventional frame-based approaches.

## 4. Source sequence generation

The source PRBS sequences stored in `reference_bits.mat` are generated with the following generators:

| Type | Length | Generator (all-ones seed) |
|---|---|---|
| `prbs7_bits` | 127 | b(k+7) = b(k) xor b(k+6), x^7 + x^6 + 1 |
| `prbs9_bits` | 511 | b(k+9) = b(k) xor b(k+5), x^9 + x^5 + 1 |
| `prbs11_bits` | 2047 | b(k+11) = b(k) xor b(k+9), x^11 + x^9 + 1 |
| `prbs20_bits` | 1048575 | b(k+20) = b(k) xor b(k+3), x^20 + x^3 + 1 |

Each PRBS sequence is transmitted at different sample rates to achieve various bit rates. During each capture session, the same sequence is repeated multiple times with a 1 s gap (0 V output voltage) in between and a 1 s 0 V tail at the end. Different PRBS sources and numbers of repetitions are used for each bit rate for better and more organized length control. The table below lists the detailed setups.

| Bit rate | Sample rate | PRBS | Bits per block | Block duration | Repeats | Total | Channels |
|---|---|---|---|---|---|---|---|
| 10 bps | 160 Sa/s | PRBS7 | 127 | 12.70 s | 2 | 27.40 s | FSO, Underwater |
| 20 bps | 320 Sa/s | PRBS7 | 127 | 6.35 s | 3 | 22.05 s | FSO, Underwater |
| 200 bps | 3.2 kSa/s | PRBS9 | 511 | 2.555 s | 7 | 24.885 s | FSO, Underwater |
| 500 bps | 8 kSa/s | PRBS9 | 511 | 1.022 s | 13 | 26.286 s | FSO, Underwater |
| 1 kbps | 16 kSa/s | PRBS9 | 511 | 0.511 s | 18 | 27.198 s | FSO, Underwater |
| 10 kbps | 160 kSa/s | PRBS11 | 2047 | 0.2047 s | 21 | 25.299 s | FSO, Underwater |
| 20 kbps | 320 kSa/s | PRBS11 | 2047 | 0.10235 s | 23 | 25.354 s | FSO, Underwater |
| **100 kbps** | 1.6 MSa/s | PRBS20 | 1048575 | 10.486 s | 1 (no repeat) | 10.486 s | **FSO only** |
| **200 kbps** | 3.2 MSa/s | PRBS20 | 1048575 | 5.243 s | 1 (no repeat) | 5.243 s | **FSO only** |

- Note that the 100 kbps and 200 kbps signals are for exploratory purposes and were therefore collected with a simpler setup (i.e., with no repetition and only over the FSO channel).

## 5. Event camera data file structure

Event data collected by the event camera are stored as `*.bin` files with the structure below. The `_cd.bin` files store the actual events, and the `_trigger.bin` files store the external trigger events (i.e., frame-start sync pulses).

A 64-byte header with the fields below is present in all `*.bin` files.

**Header (64 bytes)**

| Offset | Type | Field | Description |
|---|---|---|---|
| 0 | char[8] | magic | `EVBIN001` |
| 8 | uint16 | version | 1 |
| 10 | uint16 | header_size | 64 |
| 12 | uint16 | record_type | 1 = CD events, 2 = external trigger |
| 14 | uint16 | record_size | 13 (CD) or 10 (trigger) |
| 16 | uint16 | sensor_width | 1280 |
| 18 | uint16 | sensor_height | 720 |
| 20 | uint32 | reserved0 | 0 |
| 24 | uint64 | num_records | number of records |
| 32 | int64 | time_offset_us | absolute sensor time = t + time_offset_us |
| 40 | uint8[24] | reserved | 0 |

Following the header, the records are stored with the following fields:

**CD record, `_cd.bin` (13 bytes)**

| Offset | Type | Field | Description |
|---|---|---|---|
| 0 | uint16 | x | column pixel |
| 2 | uint16 | y | row pixel |
| 4 | uint8 | p | 1 = ON (brighter), 0 = OFF (darker) |
| 5 | int64 | t | timestamp [µs] |

- For example, `x` = 60, `y` = 200, `p` = 1, `t` = 48512 means that an ON event was detected at pixel (60, 200) 48512 µs after the time origin of the recording.

**Trigger record, `_trigger.bin` (10 bytes)**

| Offset | Type | Field | Description |
|---|---|---|---|
| 0 | uint8 | p | 1 = rising edge, 0 = falling edge |
| 1 | uint8 | id | trigger channel |
| 2 | int64 | t | timestamp [µs] |

- A record with `p` = 1 means that a new frame starts at the corresponding timestamp `t`.

## 6. Reading the files

The helper reader functions in `readers/` can be used to load `*.bin` files into the workspace. The helper functions do not require any third-party toolboxes or SDKs.

### MATLAB

```matlab
addpath('readers');
f = 'event_frame_FSO/FSO_0_5m_1kbps_On/FSO_0_5m_1kbps_On';

[ev,  hdr] = read_evbin([f '_cd.bin']);         % ev.x, ev.y, ev.p, ev.t  (t in us)
[trg, ~]   = read_evbin([f '_trigger.bin']);    % trg.p, trg.id, trg.t
part = read_evbin([f '_cd.bin'], 1, 1e6);       % first 1,000,000 events only
fprintf('%d events, sensor %dx%d\n', hdr.num_records, hdr.sensor_width, hdr.sensor_height);

% ON - OFF event count per 100 us bin (simple received waveform)
binUs = 100;
k = floor(double(ev.t - ev.t(1)) / binUs) + 1;
onOff = accumarray(k, 2 * double(ev.p) - 1);
plot((0:numel(onOff)-1) * binUs / 1e6, onOff); xlabel('time (s)');

frameStartUs = trg.t(trg.p == 1);               % frame-camera frame start times

ref = load('reference_bits.mat');               % ref.prbs9_bits is the 1 kbps block
```

### Python (numpy)

```python
import sys
sys.path.append('readers')
import numpy as np
from read_evbin import read_evbin

f = 'event_frame_FSO/FSO_0_5m_1kbps_On/FSO_0_5m_1kbps_On'
hdr, ev = read_evbin(f + '_cd.bin', mmap=True)     # ev['x'], ev['y'], ev['p'], ev['t']
hdr_t, trg = read_evbin(f + '_trigger.bin')         # trg['p'], trg['id'], trg['t']
print(hdr['num_records'], 'events')

# ON - OFF event count per 100 us bin
bin_us = 100
k = (ev['t'] - ev['t'][0]) // bin_us
on_off = np.bincount(k, weights=2.0 * ev['p'] - 1)

frame_start_us = trg['t'][trg['p'] == 1]
```

Without the reader, plain numpy also works:

```python
cd = np.fromfile(f + '_cd.bin', offset=64,
                 dtype=np.dtype([('x', '<u2'), ('y', '<u2'), ('p', 'u1'), ('t', '<i8')]))
```

`reference_bits.mat` can be read in Python with `scipy.io.loadmat`.

(Credit to Claude Code for assistance in writing the helper functions.)
