# Media aliases

# Показать доступные форматы видео
alias ydlf 'yt-dlp -F'

# Скачать видео в лучшем качестве. Можно задать ограничение по качеству флагом -q.
function ydl
    set out "$HOME/Documents/Видео/yt-dlp"
    set cookies "$out/www.youtube.com_cookies.txt" # Расширение Get cookies.txt LOCALLY
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

    yt-dlp -F $argv
    yt-dlp --cookies "$cookies" -P "$out" -f "$fmt" $argv
end

# Скачать из инсты
function idl
    set out "$HOME/Documents/Видео/inst"
    set cookies "$out/www.instagram.com_cookies.txt" # Расширение Get cookies.txt LOCALLY
    set fmt "bv*+ba/best"

    for url in $argv
        yt-dlp --cookies "$cookies" \
          -P "$out" \
          -f "$fmt" \
          --merge-output-format mp4 \
          --exec 'p={}; p=${p#\"}; p=${p%\"}; p=${p#'\''}; p=${p%'\''}; ffmpeg -hide_banner -loglevel error -y -i "$p" -c:v libx264 -crf 18 -preset veryfast -pix_fmt yuv420p -c:a copy "${p%.*}_h264.mp4" && rm "$p"' \
          "$url"
    end
end

# Скачать только аудио
alias ydla 'yt-dlp --cookies "$HOME/Documents/Видео/yt-dlp/www.youtube.com_cookies.txt" -P "$HOME/Documents/Видео/yt-dlp" -x --audio-format m4a --audio-quality 0 -f "ba"'

# Посмотреть инфу о видео
function vinfo --description "Show media info via ffprobe"
    if test (count $argv) -lt 1
        echo "Usage: vinfo <file>"
        return 2
    end

    ffprobe -hide_banner -- $argv[1]
end