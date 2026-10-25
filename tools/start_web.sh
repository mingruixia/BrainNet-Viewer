#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-or-later
# Local Linux/macOS launcher. Never installs Docker, changes permissions or pulls.
set -eu
image=${BNV_IMAGE:-mingruixia/brainnet-viewer:2.0.0}
name=brainnet-web
port=1031
backend=auto
action=start
cpus=${BNV_CPUS:-}
while [ "$#" -gt 0 ]; do
    [ "$#" -ge 2 ] || { echo "Missing argument value" >&2; exit 2; }
    case "$1" in
        --image) image=$2;; --name) name=$2;; --port) port=$2;;
        --backend) backend=$2;; --action) action=$2;; --cpus) cpus=$2;;
        *) echo "Unknown option: $1" >&2; exit 2;;
    esac
    shift 2
done
case "$image" in ''|-*|*[!A-Za-z0-9._:/@-]*) echo "Invalid image" >&2; exit 2;; esac
case "$name" in ''|-*|*[!A-Za-z0-9_.-]*) echo "Invalid container name" >&2; exit 2;; esac
case "$port" in ''|*[!0-9]*) echo "Invalid port" >&2; exit 2;; esac
[ "$port" -ge 1024 ] && [ "$port" -le 65535 ] || { echo "Port must be 1024-65535" >&2; exit 2; }
case "$backend" in auto|gpu|cpu) ;; *) echo "Backend must be auto, gpu or cpu" >&2; exit 2;; esac
case "$action" in start|stop|status|logs) ;; *) echo "Action must be start, stop, status or logs" >&2; exit 2;; esac
command -v docker >/dev/null || { echo "Docker CLI is unavailable" >&2; exit 1; }
names=$(docker container ls -a --format '{{.Names}}')
exists=false
while IFS= read -r item; do [ "$item" != "$name" ] || exists=true; done <<EOF
$names
EOF
if [ "$exists" = true ]; then
    expected=$(docker image inspect "$image" --format '{{.Id}}')
    actual=$(docker inspect "$name" --format '{{.Image}}')
    label=$(docker inspect "$name" --format '{{index .Config.Labels "org.brainnetviewer.application"}}')
    binding=$(docker inspect "$name" --format '{{with index .HostConfig.PortBindings "1031/tcp"}}{{range .}}{{.HostIp}}:{{.HostPort}}{{end}}{{end}}')
    [ "$expected" = "$actual" ] && [ "$label" = web ] && [ "$binding" = "127.0.0.1:$port" ] || {
        echo "Existing container identity or binding differs. No changes made; choose another name." >&2; exit 1;
    }
fi
case "$action" in
start)
    if [ "$exists" = true ]; then
        docker start "$name" >/dev/null
        echo "Existing container retained its original backend."
    else
        docker image inspect "$image" --format '{{.Id}}' >/dev/null || {
            echo "Load the prepared image, or pull the published version, before starting." >&2; exit 1;
        }
        available=$(docker info --format '{{.NCPU}}') || {
            echo "Cannot read Docker engine CPU availability. No container created." >&2; exit 1;
        }
        case "$available" in ''|*[!0-9]*)
            echo "Invalid Docker engine CPU count. No container created." >&2; exit 1;;
        esac
        [ "$available" -ge 1 ] || { echo "Docker engine reports no available CPUs." >&2; exit 1; }
        if [ -z "$cpus" ]; then
            cpus=$available
            [ "$available" -le 8 ] || cpus=8
        fi
        cpus=$(LC_ALL=C awk -v value="$cpus" -v available="$available" 'BEGIN {
            if (value !~ /^[0-9]+([.][0-9]+)?$/ || value+0 < 0.01 || value+0 > available+0) exit 1;
            printf "%.9g", value+0;
        }') || {
            echo "CPU limit must be 0.01 through $available (Docker engine CPUs). No container created." >&2; exit 2;
        }
        echo "CPU limit: $cpus; Docker engine CPUs: $available"
        selected=cpu
        if [ "$backend" != cpu ]; then
            if docker run --rm --pull=never --read-only --tmpfs /tmp:size=512m,mode=1777 \
                --cpus "$cpus" --memory 8g --pids-limit 256 --cap-drop ALL \
                --security-opt no-new-privileges:true --gpus all \
                --env NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute \
                --entrypoint python "$image" -m brainnet_viewer.web_backend --probe-gpu; then
                selected=gpu
            elif [ "$backend" = gpu ]; then
                echo "GPU rendering could not start. No application container created." >&2; exit 1
            else
                echo "GPU unavailable; starting CPU rendering." >&2
            fi
        fi
        runtime=$selected
        [ "$selected:$backend" != gpu:auto ] || runtime=auto
        set -- run -d --pull=never --name "$name" --label org.brainnetviewer.application=web \
            --read-only --tmpfs /tmp:size=512m,mode=1777 --cpus "$cpus" --memory 8g \
            --pids-limit 256 --cap-drop ALL --security-opt no-new-privileges:true \
            --env "BNV_RENDER_BACKEND=$runtime" -p "127.0.0.1:$port:1031"
        if [ "$selected" = gpu ]; then
            set -- "$@" --gpus all --env NVIDIA_DRIVER_CAPABILITIES=graphics,utility,compute
        fi
        if ! docker "$@" "$image" >/dev/null; then
            echo "Application startup failed. Check the full Docker error above. If the port is occupied, save the old Scene and stop only its identified container, or choose a new name AND a free port." >&2
            exit 1
        fi
        echo "Requested backend: $backend; selected: $selected"
    fi
    echo "Started. Check Docker health/logs while graphics initializes."
    echo "Browser: http://127.0.0.1:$port/index.html"
    ;;
stop) [ "$exists" = false ] || docker stop --time 10 "$name";;
logs) [ "$exists" = true ] || { echo "Container not created" >&2; exit 1; }; docker logs --tail 80 "$name";;
status) if [ "$exists" = true ]; then docker inspect "$name" --format '{{.State.Status}} | {{.State.Health.Status}} | {{.Image}}'; else echo "Container not created"; fi;;
esac
