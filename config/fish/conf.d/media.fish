# Media aliases

# Показать доступные форматы видео
alias ydlf 'yt-dlp --cookies-from-browser chrome -F'

# Скачать видео в лучшем качестве. Можно задать ограничение по качеству флагом -q.
function ydl
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

    ydlf
    yt-dlp \
        --cookies-from-browser chrome \
        -P "$out" \
        -f "$fmt" \
        $argv
end

# Скачать только аудио
function ydla
    set out "$HOME/Documents/Видео/yt-dlp"

    ydlf
    yt-dlp \
        --cookies-from-browser chrome \
        -P "$out" \
        -x --audio-format mp3 --audio-quality 0 \
        # 140 - m4a audio only (medium); bestaudio[ext=m4a] - m4a lower; bestaudio - webm and other
        -f "140/bestaudio[ext=m4a]/bestaudio" \
        $argv
end

# Скачать из инсты
function idl
    set out "$HOME/Documents/Видео/inst"
    set fmt "bv*+ba/best"

    for url in $argv
        yt-dlp \
            --cookies-from-browser chrome \
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
    set audio_out "$HOME/Documents/Видео/yt-dlp"
    set transcript_out "$HOME/Downloads"

    if test (count $argv) -eq 0
        echo "Usage: ydlt <youtube-url>"
        return 1
    end

    set audio_file (yt-dlp \
        --cookies-from-browser chrome \
        -P "$audio_out" \
        -f "140/251/bestaudio/91/18" \
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