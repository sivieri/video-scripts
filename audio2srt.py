from datetime import timedelta
import os
import whisper

def transcribe_audio(path, language):
    model = whisper.load_model("large")
    print("Whisper model loaded.")
    transcribe = model.transcribe(audio=path, task="translate", language=language)
    print(transcribe["text"])
    segments = transcribe['segments']
    srtFilename = path + "_sub.srt"

    with open(srtFilename, 'a', encoding='utf-8') as srtFile:
        for segment in segments:
            startTime = str(0)+str(timedelta(seconds=int(segment['start'])))+',000'
            endTime = str(0)+str(timedelta(seconds=int(segment['end'])))+',000'
            text = segment['text']
            segmentId = segment['id']+1
            segment = f"{segmentId}\n{startTime} --> {endTime}\n{text[1:] if text[0] == ' ' else text}\n\n"
            srtFile.write(segment)

    return srtFilename

transcribe_audio("output2.wav", "zh")
