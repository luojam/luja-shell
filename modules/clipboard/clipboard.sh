#!/usr/bin/env bash
set -euo pipefail

umask 077
pins_dir="${XDG_DATA_HOME:-$HOME/.local/share}/cliphist/pins"
temp_dir=
trap '[[ -z "$temp_dir" ]] || rm -rf -- "$temp_dir"' EXIT
trap 'exit 1' HUP INT TERM

action=${1:?Missing action}
selection=${2:-}
entry=${selection%%$'\t'*}
pin=

if [[ "$action" != list ]]; then
    if [[ "$entry" =~ ^pin:([a-f0-9]{64})$ ]]; then
        pin="$pins_dir/${BASH_REMATCH[1]}"
    elif [[ ! "$entry" =~ ^[0-9]+$ ]]; then
        echo 'Invalid clipboard entry' >&2
        exit 1
    fi
fi

case "$action" in
    list)
        for pin in "$pins_dir"/*; do
            [[ -f "$pin/data" && -f "$pin/preview" ]] || continue
            printf 'pin:%s\t★ ' "${pin##*/}"
            cat -- "$pin/preview"
        done

        temp_dir=$(mktemp -d)
        if ! cliphist list 2> "$temp_dir/error"; then
            if [[ "$(cat "$temp_dir/error")" != 'opening db: please store something first' ]]; then
                cat "$temp_dir/error" >&2
                exit 1
            fi
        fi
        ;;
    copy)
        if [[ -n "$pin" ]]; then
            wl-copy < "$pin/data"
        else
            temp_dir=$(mktemp -d)
            printf '%s' "$entry" | cliphist decode > "$temp_dir/data"
            wl-copy < "$temp_dir/data"
        fi
        ;;
    delete)
        [[ -z "$pin" ]] || exit 0
        printf '%s' "$entry" | cliphist delete
        ;;
    pin)
        if [[ -n "$pin" ]]; then
            cliphist store < "$pin/data"

            temp_dir=$(mktemp -d)
            cliphist list > "$temp_dir/history"

            restored=false
            while IFS=$'\t' read -r id _; do
                if printf '%s' "$id" | cliphist decode > "$temp_dir/data" &&
                    cmp -s -- "$pin/data" "$temp_dir/data"; then
                    restored=true
                    break
                fi
            done < "$temp_dir/history"

            if [[ "$restored" != true ]]; then
                echo 'Could not verify clipboard restoration; pin kept' >&2
                exit 1
            fi

            rm -r -- "$pin"
        else
            mkdir -p -- "$pins_dir"
            temp_dir=$(mktemp -d "$pins_dir/.pin.XXXXXX")
            printf '%s' "$entry" | cliphist decode > "$temp_dir/data"
            printf '%s\n' "${selection#*$'\t'}" > "$temp_dir/preview"

            hash=$(sha256sum "$temp_dir/data")
            hash=${hash%% *}

            if [[ -d "$pins_dir/$hash" ]]; then
                mv -T -- "$temp_dir/data" "$pins_dir/$hash/data"
                mv -T -- "$temp_dir/preview" "$pins_dir/$hash/preview"
            else
                mv -T -- "$temp_dir" "$pins_dir/$hash"
                temp_dir=
            fi
        fi
        ;;
    *)
        echo 'Unknown clipboard action' >&2
        exit 1
        ;;
esac
