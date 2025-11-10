import whisper
import sys

model = whisper.load_model("large")

# load audio and pad/trim it to fit 30 seconds
audio = whisper.load_audio(sys.argv[1])
audio = whisper.pad_or_trim(audio)

# make log-Mel spectrogram and move to the same device as the model
mel = whisper.log_mel_spectrogram(audio, n_mels=model.dims.n_mels).to(model.device)

# detect the spoken language
_, probs = model.detect_language(mel)
print(f"Detected language: {max(probs, key=probs.get)}")
