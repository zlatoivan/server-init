# Media aliases

function __yt_dlp_with_cookies
    set cookie_file $argv[1]
    set -e argv[1]

    if test -f "$cookie_file"
        yt-dlp --cookies "$cookie_file" $argv
        set status_code $status

        if test $status_code -eq 0
            return 0
        end

        printf '\033[31mCookies file failed, retrying with Chrome cookies...\033[0m\n' >&2
    else
        printf '\033[31mCookies file not found, using Chrome cookies...\033[0m\n' >&2
    end

    yt-dlp --cookies-from-browser chrome $argv
end

function __yt_subtitles_to_txt
    set cookie_file $argv[1]
    set transcript_out $argv[2]
    set -e argv[1]
    set -e argv[1]

    set subtitles_tmp (mktemp -d)

    __yt_dlp_with_cookies "$cookie_file" \
        --skip-download \
        --write-subs \
        --write-auto-subs \
        --sub-langs "ru.*,en.*" \
        --sub-format vtt \
        --convert-subs vtt \
        -P "$subtitles_tmp" \
        --quiet \
        --no-warnings \
        $argv

    if test $status -ne 0
        rm -rf "$subtitles_tmp"
        return 1
    end

    set subtitle_file (python3 -c 'import glob
import os
import sys

files = glob.glob(os.path.join(sys.argv[1], "*.vtt"))
print(max(files, key=os.path.getmtime) if files else "")
' "$subtitles_tmp")

    if test -z "$subtitle_file"
        rm -rf "$subtitles_tmp"
        return 1
    end

    set transcript_file (python3 -c 'import html
import re
import sys
from pathlib import Path

vtt_path = Path(sys.argv[1])
transcript_out = Path(sys.argv[2])

stem = re.sub(r"\.vtt$", "", vtt_path.name)
stem = re.sub(r"\.[a-z]{2,3}(?:[-_][A-Za-z0-9]+)?(?:-orig)?$", "", stem)
txt_path = transcript_out / f"{stem}.txt"

lines = vtt_path.read_text(encoding="utf-8").splitlines()
result = []
previous = ""

for line in lines:
    line = line.strip()

    if not line:
        continue

    if line == "WEBVTT":
        continue

    if line.startswith(("Kind:", "Language:", "NOTE")):
        continue

    if "-->" in line:
        continue

    if line.isdigit():
        continue

    line = re.sub(r"<[^>]+>", "", line)
    line = html.unescape(line).strip()

    if not line:
        continue

    if line == previous:
        continue

    result.append(line)
    previous = line

if not result:
    sys.exit(1)

txt_path.parent.mkdir(parents=True, exist_ok=True)
txt_path.write_text(" ".join(result) + "\n", encoding="utf-8")
print(txt_path)
' "$subtitle_file" "$transcript_out")

    set status_code $status
    rm -rf "$subtitles_tmp"

    if test $status_code -ne 0
        return 1
    end

    printf '%s\n' "$transcript_file"
end

# Показать доступные форматы видео
function ydlf
    set cookies "$HOME/Documents/Видео/yt-dlp/www.youtube.com_cookies.txt"

    __yt_dlp_with_cookies "$cookies" -F $argv
end

# Скачать видео в лучшем качестве. Можно задать ограничение по качеству флагом -q.
function ydl
    set cookies "$HOME/Documents/Видео/yt-dlp/www.youtube.com_cookies.txt"
    set out "$HOME/Documents/Видео/yt-dlp"
    set default_q 1080
    set fmt "bv[height<=$default_q][ext=mp4]+ba[ext=m4a]/b[height<=$default_q][ext=mp4]"

    argparse 'q=' -- $argv; or return 2
    if set -q _flag_q
        if string match -qr '^[0-9]+$' -- $_flag_q
            set fmt "bv[height<=$_flag_q][ext=mp4]+ba[ext=m4a]/b[height<=$_flag_q][ext=mp4]"
        else
            echo "Некорректное значение -q: $_flag_q" >&2
            return 1
        end
    end

    ydlf $argv
    __yt_dlp_with_cookies "$cookies" \
        -P "$out" \
        -f "$fmt" \
        $argv
end

# Скачать только аудио
function ydla
    set cookies "$HOME/Documents/Видео/yt-dlp/www.youtube.com_cookies.txt"
    set out "$HOME/Documents/Видео/yt-dlp"

    __yt_dlp_with_cookies "$cookies" \
        -P "$out" \
        -x --audio-format mp3 --audio-quality 0 \
        # 140 - m4a audio only (medium); bestaudio[ext=m4a] - m4a lower; bestaudio - webm and other
        -f "140/bestaudio[ext=m4a]/bestaudio" \
        $argv
end

# Скачать из инсты
function idl
    set cookies "$HOME/Documents/Видео/inst/www.instagram.com_cookies.txt"
    set out "$HOME/Documents/Видео/inst"
    set fmt "bv*+ba/best"

    for url in $argv
        __yt_dlp_with_cookies "$cookies" \
            -P "$out" \
            -f "$fmt" \
            --merge-output-format mp4 \
            --exec 'p={}; p=${p#\"}; p=${p%\"}; p=${p#'\''}; p=${p%'\''}; ffmpeg -hide_banner -loglevel error -y -i "$p" -c:v libx264 -crf 18 -preset veryfast -pix_fmt yuv420p -c:a copy "${p%.*}_h264.mp4" && rm "$p"' \
            "$url"
    end
end

# Скачать только аудио из инсты
function idla
    set cookies "$HOME/Documents/Видео/inst/www.instagram.com_cookies.txt"
    set out "$HOME/Documents/Видео/inst"

    for url in $argv
        __yt_dlp_with_cookies "$cookies" \
            -P "$out" \
            -x --audio-format mp3 --audio-quality 0 \
            -f "bestaudio/best" \
            "$url"
    end
end

# Посмотреть инфу о видео
function vinfo --description "Show media info via ffprobe"
    if test (count $argv) -lt 1
        echo "Usage: vinfo <file>"
        return 2
    end

    ffprobe -hide_banner -- $argv[1]
end

# Скачать видео и аудио и сделать транскрибацию
function ydlt
    set cookies "$HOME/Documents/Видео/yt-dlp/www.youtube.com_cookies.txt"
    set audio_out "$HOME/Documents/Видео/transcription"
    set transcript_out "$HOME/Documents/Видео/transcription"

    echo "Trying YouTube captions..."
    set transcript_file (__yt_subtitles_to_txt "$cookies" "$transcript_out" $argv)
    if test $status -eq 0
        echo "Transcript from YouTube captions: $transcript_file"
        echo "Transcript folder: $transcript_out"
        python3 -c 'from pathlib import Path
import sys

print(Path(sys.argv[1]).as_uri())
' "$transcript_out"
        return 0
    end

    echo "YouTube captions not found, falling back to mlx_whisper..."
    echo "Downloading audio..."
    set audio_file (__yt_dlp_with_cookies "$cookies" \
        -P "$audio_out" \
        -f "140/bestaudio[ext=m4a]/bestaudio" \
        --quiet \
        --no-warnings \
        --no-simulate \
        --print after_move:filepath \
        $argv)

    if test $status -ne 0
        echo "yt-dlp failed"
        return 1
    end

    set transcript_file (python3 -c 'from pathlib import Path
import sys

audio_file = Path(sys.argv[1])
transcript_out = Path(sys.argv[2])
print(transcript_out / audio_file.with_suffix(".txt").name)
' "$audio_file" "$transcript_out")

    if test -f "$transcript_file"
        echo "Transcript already exists: $transcript_file"
        if test -f "$audio_file"
            rm "$audio_file"
        end

        touch "$transcript_file"
        echo "Transcript folder: $transcript_out"
        python3 -c 'from pathlib import Path
import sys

print(Path(sys.argv[1]).as_uri())
' "$transcript_out"
        return 0
    end

    echo "Transcribing audio..."
    mlx_whisper "$audio_file" \
        --model mlx-community/whisper-large-v3-turbo \
        --language ru \
        --output-dir "$transcript_out" \
        --output-format txt

    if test $status -ne 0
        echo "mlx_whisper failed"
        return 1
    end

    if test -f "$audio_file"
        rm "$audio_file"
    end

    echo "Transcript folder: $transcript_out"
    python3 -c 'from pathlib import Path
import sys

print(Path(sys.argv[1]).as_uri())
' "$transcript_out"
end

function txtsummary
    if test (count $argv) -lt 1
        echo "Usage: txtsummary <transcript.txt>"
        return 2
    end

    set transcript_file $argv[1]

    if not test -f "$transcript_file"
        echo "Transcript file not found: $transcript_file" >&2
        return 1
    end

    echo "Preparing Claude prompt..."
    begin
        echo "Саммаризируй материал:"
        echo
        cat "$transcript_file"
    end | pbcopy

    open "https://claude.ai/new"
    echo "Prompt copied to clipboard. Paste it into Claude with Cmd+V."
end

# Скачать аудио, сделать транскрибацию и подготовить саммаризацию в Claude
function ydls
    set transcript_out "$HOME/Documents/Видео/transcription"

    ydlt $argv
    if test $status -ne 0
        return 1
    end

    echo "Finding transcript..."
    set transcript_file (python3 -c 'import glob
import os
import sys

files = glob.glob(os.path.join(sys.argv[1], "*.txt"))
print(max(files, key=os.path.getmtime) if files else "")
' "$transcript_out")

    if test -z "$transcript_file"
        echo "Transcript file not found in $transcript_out" >&2
        return 1
    end

    txtsummary "$transcript_file"
end

# Сделать транскрибацию .mov и подготовить саммаризацию в Claude
function movs
    if test (count $argv) -lt 1
        echo "Usage: movs <video.mov>"
        return 2
    end

    set video_file $argv[1]
    set transcript_out "$HOME/Documents/Видео/transcription"

    if not test -f "$video_file"
        echo "Video file not found: $video_file" >&2
        return 1
    end

    set transcript_file (python3 -c 'from pathlib import Path
import sys

video_file = Path(sys.argv[1])
transcript_out = Path(sys.argv[2])
print(transcript_out / video_file.with_suffix(".txt").name)
' "$video_file" "$transcript_out")

    if test -f "$transcript_file"
        echo "Transcript already exists: $transcript_file"
        touch "$transcript_file"
    else
        echo "Transcribing video..."
        mlx_whisper "$video_file" \
            --model mlx-community/whisper-large-v3-turbo \
            --language ru \
            --output-dir "$transcript_out" \
            --output-format txt

        if test $status -ne 0
            echo "mlx_whisper failed"
            return 1
        end
    end

    txtsummary "$transcript_file"
end

# Сделать конспект транскрипции через OpenAI
function ydlsa
    if test (count $argv) -lt 1
        echo "Usage: ydls <youtube-url>"
        return 2
    end

    if not set -q OPENAI_API_KEY
        echo "OPENAI_API_KEY is not set" >&2
        return 1
    end

    set transcript_out "$HOME/Documents/Видео/transcription"

    ydlt $argv
    if test $status -ne 0
        return 1
    end

    echo "Finding transcript..."
    set transcript_file (python3 -c 'import glob
import os
import sys

files = glob.glob(os.path.join(sys.argv[1], "*.txt"))
print(max(files, key=os.path.getmtime) if files else "")
' "$transcript_out")

    if test -z "$transcript_file"
        echo "Transcript file not found in $transcript_out" >&2
        return 1
    end

    set model gpt-5.4-mini
    if set -q OPENAI_SUMMARY_MODEL
        set model $OPENAI_SUMMARY_MODEL
    end

    set output_file (string replace -r '\.[^.]*$' '.summary.md' -- "$transcript_file")
    if test "$output_file" = "$transcript_file"
        set output_file "$transcript_file.summary.md"
    end

    echo "Sending transcript to OpenAI..."
    python3 -c '
import json
import os
import sys
import urllib.error
import urllib.request

transcript_path, output_path, model = sys.argv[1:4]
api_key = os.environ.get("OPENAI_API_KEY")

with open(transcript_path, "r", encoding="utf-8") as transcript_file:
    transcript = transcript_file.read()

prompt = """Саммаризируй"""

payload = {
    "model": model,
    "input": [
        {
            "role": "user",
            "content": prompt + "\n\nМатериал:\n" + transcript,
        }
    ],
}

request = urllib.request.Request(
    "https://api.openai.com/v1/responses",
    data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
    headers={
        "Authorization": "Bearer " + api_key,
        "Content-Type": "application/json",
    },
    method="POST",
)

try:
    with urllib.request.urlopen(request) as response:
        data = json.load(response)
except urllib.error.HTTPError as error:
    print(error.read().decode("utf-8"), file=sys.stderr)
    sys.exit(1)

summary = data.get("output_text")
if not summary:
    chunks = []
    for item in data.get("output", []):
        for content in item.get("content", []):
            text = content.get("text")
            if text:
                chunks.append(text)
    summary = "\n".join(chunks).strip()

if not summary:
    print(json.dumps(data, ensure_ascii=False, indent=2), file=sys.stderr)
    sys.exit(1)

with open(output_path, "w", encoding="utf-8") as summary_file:
    summary_file.write(summary.rstrip() + "\n")

print(output_path)
' "$transcript_file" "$output_file" "$model"
end