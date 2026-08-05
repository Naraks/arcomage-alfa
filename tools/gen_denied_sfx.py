"""Generate card_denied.wav — short descending buzz for "can't afford" feedback."""
import wave, struct, math, os

SAMPLE_RATE = 44100
DURATION    = 0.18   # seconds
FREQ_START  = 320.0  # Hz
FREQ_END    = 140.0  # Hz

n_samples = int(SAMPLE_RATE * DURATION)
samples = []
for i in range(n_samples):
    t = i / SAMPLE_RATE
    phase = t / DURATION
    # Exponential frequency glide (descending)
    freq = FREQ_START * ((FREQ_END / FREQ_START) ** phase)
    # Accumulate phase properly to avoid discontinuities
    angle = 2 * math.pi * freq * t
    # Soft-clipped sine for a slightly gritty "denied" timbre
    raw = math.sin(angle)
    clipped = math.tanh(raw * 2.5) / math.tanh(2.5)
    # Exponential fade-out envelope
    envelope = math.exp(-4.0 * phase)
    value = int(clipped * envelope * 28000)
    samples.append(struct.pack('<h', max(-32768, min(32767, value))))

out_path = os.path.join(os.path.dirname(__file__),
                        '..', 'audio', 'sfx', 'card_denied.wav')
out_path = os.path.normpath(out_path)
with wave.open(out_path, 'w') as wf:
    wf.setnchannels(1)
    wf.setsampwidth(2)
    wf.setframerate(SAMPLE_RATE)
    wf.writeframes(b''.join(samples))

print(f"Written {n_samples} samples -> {out_path}")
