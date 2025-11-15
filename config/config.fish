# Starship
set fish_greeting
starship init fish | source

# GPG key
export GPG_TTY=$(tty)

# Docker (for route 256)
# set -x DOCKER_HOST unix://$HOME/.colima/default/docker.sock
# set -x TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE /var/run/docker.sock

# Go

alias gmt   'go mod tidy'
alias gmd   'go mod download'

# sbp

alias sbp-rec-t 'env MallocNanoZone=0 VAULT_ADDR="" BOZON_SBP_RECONCILER_LOCAL_CONFIG_ENABLED=true BOZON_SBP_RECONCILER_LOCAL_CONFIG_PATH="/Users/izlatovratskiy/GolandProjects/1-озon/sbp-reconciler/.o3/k8s" BOZON_SBP_RECONCILER_LOCAL_CONFIG_NAME="values_local.yaml" BOZON_SBP_RECONCILER_APP_ENV="test" go test'

# Aliases docker

alias dps   'docker ps'
alias dpsa  'docker ps -a'

function drma # alias drma  'docker rm -v -f $(docker ps -qa)'
    set c (docker ps -qa)
    test (count $c) -gt 0;
    and docker rm -v -f $c;
    or echo "No containers to remove."
end

function drme # alias drme  'docker rm -v $(docker ps --filter status=exited -q)'
    set c (docker ps --filter status=exited -q)
    test (count $c) -gt 0;
    and docker rm -v $c;
    or echo "No exited containers to remove."
end

function dpss # Вывести только имена контейнеров и их порты на расстоянии 4 символа друг от друга
	docker ps --format '{{.Names}}|{{.Ports}}' | awk -F'|' '{a[NR]=$1; b[NR]=$2; if(length($1)>m)m=length($1)} END{p=m+4; for(i=1;i<=NR;i++) printf "%-*s%s\n",p,a[i],b[i]}'
end

# Aliases git

# branch
alias gco   'git checkout'
alias gcb   'git checkout -b'
alias gcm   'git checkout master'
alias gch   'git checkout HEAD --'
alias gb    'git branch'
alias gbd   'git branch -d'
alias gbD   'git branch -D'
alias gbv   'git branch -vv'
alias grv   'git remote -v'
function gcbm # Создать ветку с состоянием мастера
    if test (count $argv) -ne 1
        echo "Usage: gcbm <branch-name>"
        return 1
    end
    git checkout -b $argv[1]
    and git fetch
    and git reset --hard origin/master
end

# commit
alias gs    'git status'
alias ga    'git add'
alias gc    'git commit -m'
alias gca   'git commit --amend -m'
alias gac   'git add -A && git commit -m'
alias gaca  'git add -A && git commit --amend --no-edit'
alias gacap 'git add -A && git commit --amend --no-edit && git push -f'
function gacp # Добавить все изменения, сделать коммит и запушить
    git add -A
    git commit -m "$argv"
    git push -f
end
function gacb # Добавить все изменения, сделать коммит, в название которого подтянется номер задачи из названия ветки
		set branch (git branch --show-current)
    set task (string split "/" $branch)[-1]
    set message (test -n "$task"; and echo "[$task] "; or echo "")$argv
    git add -A
    git commit -m "$message"
end
function gacbp # Добавить все изменения, сделать коммит, в название которого подтянется номер задачи из названия ветки и запушить
		set branch (git branch --show-current)
    set task (string split "/" $branch)[-1]
    set message (test -n "$task"; and echo "[$task] "; or echo "")$argv
    git add -A
    git commit -m "$message"
    git push -f
end
function gcap # Переименовать последний коммит и запушить
    git commit --amend -m "$argv"
    git push -f
end
function gcab # Переименовать последний коммит, в название которого подтянется номер задачи из названия ветки
    set branch (git branch --show-current)
    set task (string split "/" $branch)[-1]
    set message "[$task] $argv"
    git commit --amend -m "$message"
end
function gcabp # Переименовать последний коммит, в название которого подтянется номер задачи из названия ветки и запушить
    set branch (git branch --show-current)
    set task (string split "/" $branch)[-1]
    set message "[$task] $argv"
    git commit --amend -m "$message"
    git push -f
end

# push
alias gp    'git push'
alias gpf   'git push -f'
alias gpu   'git push -u origin'
alias gpub  'git push -u origin $(git branch --show-current)'
alias gpd   'git push -d origin'

# merge
alias gf    'git fetch'
alias grb   'git rebase'
alias grbm  'git rebase origin/master'
alias grbi  'git rebase -i' 
alias grbim 'git rebase -i origin/master'
alias grbc  'git rebase --continue'
alias grba  'git rebase --abort'
alias gm    'git merge'
alias gpl   'git pull'
alias gcp   'git cherry-pick'
alias gcps  'git cherry-pick --skip'
alias gcpc  'git cherry-pick --continue'
alias gcpa  'git cherry-pick --abort'

# reset
alias gr    'git reset'
alias grs   'git reset --soft'
alias grh   'git reset --hard'
alias grhm  'git fetch && git reset --hard origin/master'
alias grhh  'git reset --hard HEAD'
alias gr1   'git reset HEAD~1'
alias grs1  'git reset --soft HEAD~1'
alias grh1  'git reset --hard HEAD~1'
alias gcl   'git clean -fd'

# diff
alias gd    'git diff'
alias gds   'git diff --stat'
alias gdss  'git diff --shortstat'
alias gcv   'git cherry -v --abbrev=8 origin/master'

# log
alias gl    'git log'  
alias glo   'git log --oneline'  
alias glp   'git log --pretty=format:"%C(yellow)%h %C(red)%cd %C(blue)%cn %C(default)%s%C(green)%d" --date=format:"%d.%m.%y %H:%M"'  
alias glpa  'git log --pretty=format:"%C(yellow)%h %C(red)%cd %C(blue)%cn %C(default)%s%C(green)%d" --date=format:"%d.%m.%y %H:%M" --all'  
alias glpr  'git log --pretty=format:"%C(yellow)%h %C(red)%cd %C(blue)%cn %C(default)%s%C(green)%d" --date=format:"%d.%m.%y %H:%M" --reflog' # обход графа коммитов, исключая дубликаты  
alias glpg  'git log --pretty=format:"%C(yellow)%h %C(red)%cd %C(blue)%cn %C(default)%s%C(green)%d" --date=format:"%d.%m.%y %H:%M" --graph'  
alias glpd  'git log --pretty=format:"%C(yellow)%h %C(red)%cd %C(blue)%cn %C(default)%s%C(green)%d" --date=format:"%d.%m.%y %H:%M" --graph --left-right --cherry-pick HEAD...@{u}'  
alias grl   'git reflog'  
alias grlp  'git reflog --pretty=format:"%C(yellow)%h %C(red)%cd %C(blue)%an %C(default)%gs%C(green)%d" --date=format:"%d.%m.%y %H:%M"'

function gltc # Вывести топ n коммитов по insertions
    switch (count $argv)
        case 0
            set n 10
        case 1
            if not string match -qr '^[0-9]+$' $argv[1] # -q убирает вывод (тихий режим)
                echo "Error: Argument must be a number"
                return 1
            end
            set n $argv[1]
        case '*'
            echo "Usage: gltc <number>"
            return 1
    end

    git log --pretty=format:"%h %ad %an %s" --date=format:"%d.%m.%y %H:%M" --shortstat | awk '
    BEGIN{
        Y="\033[33m"; R="\033[31m"; B="\033[34m"; X="\033[0m"
    }
    /^[a-f0-9]{7}/{
        if(h) print Y h X,R d X,t "\t",B a X,X m X;
        h=$1; d=$2" "$3; a=$4; m=""; t=0;
        for(i=5;i<=NF;i++)if($i~/\[/){for(;i<=NF;i++)m=m?m" "$i:$i;break}else a=a" "$i
    }
    /files? changed/{
        t+=$(NF-3) # -$(NF-1) для вычета deleted
    }
    END{
        if(h) print Y h X,R d X,t "\t",B a X,X m X
    }' | sort -k4 -nr | head -n $n
end

function gpla # Сделать git pull рекурсивно для всех проектов текущей дириктории
	for repo in (find . -type d -name .git -print | sed 's|/\.git$||')
	    echo "==> $repo"
	    git -C "$repo" pull --ff-only --tags
	end
end

# Dop

function rmds --description 'Удалить все .DS_Store'
	find . -name '.DS_Store' -type f -delete
end

# Показать доступные форматы
alias ydlf 'yt-dlp -F'
# Скачать видео в лучшем качестве. Можно задать ограничение по качеству флагом -q.
function ydl
    set -l out "$HOME/Documents/Видео/yt-dlp"
    set -l fmt 'bv[ext=mp4]+ba[ext=m4a]/b[ext=mp4]'
    
    argparse 'q=' -- $argv; or return 2
    set -q _flag_q;
    and string match -qr '^[0-9]+$' -- $_flag_q;
    and set fmt "bv[height<=$_flag_q][ext=mp4]+ba[ext=m4a]/b[height<=$_flag_q][ext=mp4]"
    
		yt-dlp -F $argv
    yt-dlp -P "$out" -f "$fmt" $argv
end
# Скачать только аудио
alias ydla 'yt-dlp -P "$HOME/Documents/Видео/yt-dlp" -x --audio-format m4a --audio-quality 0 -f "ba"'

# Сгенерировать .dot -> .svg (принимает base или file)
function gdot --description 'base/base.dot -> base.svg'
    if test (count $argv) -eq 0
        echo 'usage: gdot <file-or-base> ...'
        return 1
    end
    type -q dot; or begin
        echo 'dot not found'
        return 1
    end
    for x in $argv
        set f $x
        if not test -f "$f"
            if test -f "$x.dot"
                set f "$x.dot"
            else
                echo "not found: $x(.dot)"
                return 1
            end
        end
        set out (string replace -r '\.dot$' '.svg' -- "$f")
        dot -Tsvg "$f" -o "$out"; or return 1
    end
end

# Сгенерировать .mmd/.mermaid -> .svg (принимает base или file)
function gmmd --description 'base/base.mmd/.mermaid -> base.svg'
    if test (count $argv) -eq 0
        echo 'usage: gmmd <file-or-base> ...'
        return 1
    end
    type -q mmdc; or begin
        echo 'mmdc not found'
        return 1
    end
    for x in $argv
        set f $x
        if not test -f "$f"
            for e in .mmd .mermaid
                if test -f "$x$e"
                    set f "$x$e"
                    break
                end
            end
            test -f "$f"; or begin
                echo "not found: $x(.mmd|.mermaid)"
                return 1
            end
        end
        set out (string replace -r '\.(mmd|mermaid)$' '.svg' -- "$f")
        mmdc -i "$f" -o "$out"; or return 1
    end
end

function kill-port # Убить конкретный занятый порт
    if test (count $argv) -ne 1
        echo "Usage: kill-port <port>"
        return 1
    end

    set port $argv[1]
    set pids (lsof -ti :$port | grep -v 'com.docker')
    if test -z "$pids"
        echo "No processes found on port $port"
        return 0
    end

    echo "Killing processes on port $port: $pids"
    for pid in $pids
        kill -9 $pid
    end
end

function lcnt # Количество строк, полный отчет
    set total (find . -type f -name '*.go' | xargs cat | wc -l)	# Все .go
    set test (find . -type f -name '*_test.go' | xargs cat | wc -l) # Тестовые
    set mocks (find . -type f \( -name "mock*.go" -o -path "*/mock*/*" \) | xargs cat | wc -l) # mocks
    set pb (find . -type f -name '*.pb*.go' | xargs cat | wc -l) # pb
    set clean (find . -type f -name '*.go' ! -name '*_test.go' ! -name 'mock*.go' ! -path '*/mock*/*' ! -name '*.pb*.go' | xargs cat | wc -l) # Смысловые .go без моков, тестов и pb

    echo "$total total go"
    echo "$clean clean go"
    echo "$test test"
    echo "$mocks mocks"
    echo "$pb pb"
end

function lcnta # Количество чистых строк .go файлов по всем проектам текущей папки
	for d in */; 
	    set name (basename $d); 
	    set count (find $d -type d \( -name .git -o -name vendor -o -name vendor.protogen \) -prune -o -type f -name '*.go' ! -name '*_test.go' ! -name 'mock*.go' ! -path '*/mock*/*' ! -name '*.pb*.go' -print0 | xargs -0 cat 2>/dev/null | wc -l | awk '{print $1}')
	    printf "%s\t%s\n" $name $count
	end | sort -k2,2nr | awk -F'\t' '{lines[NR]=$0; if (length($1)>max) max=length($1)} END {for(i=1;i<=NR;i++){split(lines[i],a,FS); printf "%-*s %s\n", max, a[1], a[2]}}'
end

function dus --description 'Размеры папок (включая скрытые), по убыванию'
    du -sh .??*/ */ 2>/dev/null | sort -hr
end

function dusv --description 'Размеры только видимых папок, по убыванию'
    du -sh */ 2>/dev/null | sort -hr
end

function dustop --argument-names n --description 'Топ-N папок по размеру (по умолчанию 20)'
    if test -z "$n"
        set n 20
    end
    du -sh .??*/ */ 2>/dev/null | sort -hr | head -n $n
end