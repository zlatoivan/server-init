# File aliases

function rmds --description 'Удалить все .DS_Store'
	find . -name '.DS_Store' -type f -delete
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
