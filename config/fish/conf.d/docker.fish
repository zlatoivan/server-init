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