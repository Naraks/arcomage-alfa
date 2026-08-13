"""Generate card_hover_rustle.wav — dry "paper rustle" cue for card hover feedback.

Regenerated to fix an audible "tripling" artifact in the previous version of this file
(see GitHub Issue ARC-089): that version was synthesized with a
sparse/coarse grain process whose amplitude envelope happened to cluster into three separate
loud bursts separated by near-silent gaps (envelope dropping back down to the noise floor
twice mid-clip) — audibly indistinguishable from the sound playing three times in a row.

This version uses:
  - FFT brickwall bandpass noise (linear phase, no resonant IIR ringing) for the base "dry
    paper" texture, ~1.2-14 kHz.
  - A single smooth attack/decay amplitude envelope (fast attack, one continuous decay to
    zero) — no secondary humps, so there is exactly one perceived "swish", not several.
  - Dense, fine-grained multiplicative jitter (a few-ms-scale random texture) layered on top
    for the crinkled-paper character, kept within a bounded range so it never drops back to
    the noise floor mid-clip the way the old sparse grains did.
"""
import wave, struct, math, os
import numpy as np

SAMPLE_RATE = 44100
DURATION = 0.30  # seconds
BAND_LOW = 1200.0  # Hz
BAND_HIGH = 14000.0  # Hz

rng = np.random.default_rng(20260807)

n_samples = int(SAMPLE_RATE * DURATION)

# --- 1. Broadband noise bed, brickwall-bandpass filtered in the frequency domain. ---
noise = rng.uniform(-1.0, 1.0, n_samples)
spectrum = np.fft.rfft(noise)
freqs = np.fft.rfftfreq(n_samples, d=1.0 / SAMPLE_RATE)
band_mask = (freqs >= BAND_LOW) & (freqs <= BAND_HIGH)
spectrum[~band_mask] = 0.0
filtered = np.fft.irfft(spectrum, n=n_samples)
filtered /= np.max(np.abs(filtered)) + 1e-9

# --- 2. Single smooth attack/decay envelope (one hump, no repeated bursts). ---
t = np.arange(n_samples) / SAMPLE_RATE
attack_time = 0.012
envelope = np.empty(n_samples)
attack_n = int(attack_time * SAMPLE_RATE)
envelope[:attack_n] = (t[:attack_n] / attack_time) ** 0.6
decay_t = t[attack_n:] - attack_time
envelope[attack_n:] = np.exp(-5.5 * decay_t / (DURATION - attack_time))
envelope *= 1.0  # peak normalized to 1 at the end of attack

# --- 3. Fine, dense multiplicative texture jitter (paper "crinkle"), bounded so it never
#        collapses the sound back to near-silence mid-clip. ---
jitter_rate_hz = 260.0  # control-point rate; interpolated for smoothness
n_ctrl = int(DURATION * jitter_rate_hz) + 2
ctrl = rng.uniform(0.55, 1.15, n_ctrl)
ctrl_t = np.linspace(0, DURATION, n_ctrl)
jitter = np.interp(t, ctrl_t, ctrl)

signal = filtered * envelope * jitter

# --- 4. Quiet continuous noise floor underneath, so the texture never truly hits zero
#        before the final fade-out (avoids any "gap" that could read as a second onset). ---
floor_noise = rng.uniform(-1.0, 1.0, n_samples)
floor_spec = np.fft.rfft(floor_noise)
floor_spec[~band_mask] = 0.0
floor_filtered = np.fft.irfft(floor_spec, n=n_samples)
floor_filtered /= np.max(np.abs(floor_filtered)) + 1e-9
signal += floor_filtered * 0.04 * envelope

# --- 5. Final normalize + short fade-out tail to avoid an end-click. ---
signal /= np.max(np.abs(signal)) + 1e-9
signal *= 0.55  # headroom; AudioManager call site already applies -6 dB on top

fade_out_n = int(0.01 * SAMPLE_RATE)
fade = np.linspace(1.0, 0.0, fade_out_n)
signal[-fade_out_n:] *= fade

pcm = np.clip(signal * 32767, -32768, 32767).astype(np.int16)

out_path = os.path.join(os.path.dirname(__file__), '..', 'audio', 'sfx', 'card_hover_rustle.wav')
out_path = os.path.normpath(out_path)
with wave.open(out_path, 'w') as wf:
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(SAMPLE_RATE)
    wf.writeframes(pcm.tobytes())

print(f"Written {n_samples} samples -> {out_path}")
