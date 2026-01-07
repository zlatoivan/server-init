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
function gacbpub # Добавить все изменения, сделать коммит, в название которого подтянется номер задачи из названия ветки и запушить первый раз
    set branch (git branch --show-current)
    set task (string split "/" $branch)[-1]
    set message (test -n "$task"; and echo "[$task] "; or echo "")$argv
    git add -A
    git commit -m "$message"
    git push -u origin $branch
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
alias gf     'git fetch'
alias grb    'git rebase'
alias grbm   'gf && git rebase origin/master'
alias grbmid 'gf && git rebase origin/master --ignore-date'
alias grbim  'gf && git rebase -i origin/master'
alias grbi   'git rebase -i'
alias grbc   'git rebase --continue'
alias grba   'git rebase --abort'
alias gm     'git merge'
alias gpl    'git pull'
alias gcp    'git cherry-pick'
alias gcps   'git cherry-pick --skip'
alias gcpc   'git cherry-pick --continue'
alias gcpa   'git cherry-pick --abort'
alias gclo   'git clone'

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
alias gst   'git stash'
alias gsta  'git stash apply'
alias gstp  'git stash pop'

# diff
alias gd    'git diff'
alias gds   'git diff --stat'
alias gdss  'git diff --shortstat'
alias gsh   'git show'
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
