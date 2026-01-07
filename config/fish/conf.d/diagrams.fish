# Diagrams aliases

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