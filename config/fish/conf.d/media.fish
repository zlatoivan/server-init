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

    mlx_whisper "$audio_file" \
        --model mlx-community/whisper-large-v3-turbo \
        --language ru \
        --output-dir "$transcript_out" \
        --output-format txt
end

# Сделать конспект транскрипции через OpenAI
function ydls
    if test (count $argv) -lt 1
        echo "Usage: ydls <transcript.txt>"
        return 2
    end

    set transcript_file $argv[1]

    if not test -f "$transcript_file"
        echo "Transcript file not found: $transcript_file" >&2
        return 1
    end

    if not set -q OPENAI_API_KEY
        echo "OPENAI_API_KEY is not set" >&2
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

prompt = """Проанализируй транскрипцию.

Сделай:
1. Главную идею в 2-3 предложениях
2. 7-10 ключевых тезисов
3. Все практические рекомендации
4. Важные цифры и исследования, упомянутые автором
5. Отдельно: спорные / неподтвержденные утверждения
6. Итоговый actionable checklist

Не добавляй информацию, которой нет в транскрипции."""

payload = {
    "model": model,
    "input": [
        {
            "role": "user",
            "content": prompt + "\n\nТранскрипция:\n" + transcript,
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