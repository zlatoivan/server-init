# Other aliases

# sbp

alias sbp-rec-t 'env MallocNanoZone=0 VAULT_ADDR="" BOZON_SBP_RECONCILER_LOCAL_CONFIG_ENABLED=true BOZON_SBP_RECONCILER_LOCAL_CONFIG_PATH="/Users/izlatovratskiy/GolandProjects/1-озon/sbp-reconciler/.o3/k8s" BOZON_SBP_RECONCILER_LOCAL_CONFIG_NAME="values_local.yaml" BOZON_SBP_RECONCILER_APP_ENV="test" go test'

# Dop

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