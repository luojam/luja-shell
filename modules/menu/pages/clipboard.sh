#!/usr/bin/env bash
set -euo pipefail

umask 077
pins_dir="${XDG_DATA_HOME:-$HOME/.local/share}/cliphist/pins"
temp_dir=
trap '[[ -z "$temp_dir" ]] || rm -rf -- "$temp_dir"' EXIT
trap 'exit 1' HUP INT TERM

action=${1:?Missing action}
entry=${2:-}
pin=

if [[ "$action" != list && "$action" != current ]]; then
    if [[ "$entry" =~ ^pin:([a-f0-9]{64})$ ]]; then
        pin="$pins_dir/${BASH_REMATCH[1]}"
    elif [[ ! "$entry" =~ ^[0-9]+$ ]]; then
        echo 'Invalid clipboard entry' >&2
        exit 1
    fi
fi

case "$action" in
    current)
        types=$(timeout 2 wl-paste --list-types 2>/dev/null) || exit 0
        case $'\n'"$types"$'\n' in
            *$'\nx-kde-passwordManagerHint\n'*) exit 0 ;;
        esac

        if ! hash=$(timeout 2 wl-paste --no-newline --type text/plain 2>/dev/null | sha256sum) &&
            ! hash=$(timeout 2 wl-paste --no-newline --type image 2>/dev/null | sha256sum); then
            exit 0
        fi

        hash=${hash%% *}
        if [[ -f "$pins_dir/$hash/data" && -f "$pins_dir/$hash/preview" ]]; then
            printf 'pin:%s\n' "$hash"
            exit 0
        fi

        ids=$(cliphist list | cut -f1)
        while IFS= read -r id; do
            [[ -n "$id" ]] || continue
            if entry_hash=$(printf '%s' "$id" | cliphist decode | sha256sum) &&
                [[ "${entry_hash%% *}" == "$hash" ]]; then
                printf '%s\n' "$id"
                break
            fi
        done <<< "$ids"
        ;;
    list)
        for pin in "$pins_dir"/*; do
            [[ -f "$pin/data" && -f "$pin/preview" ]] || continue
            printf 'pin:%s\t' "${pin##*/}"
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
    image)
        if [[ -n "$pin" ]]; then
            base64 --wrap=0 < "$pin/data"
        else
            printf '%s' "$entry" | cliphist decode | base64 --wrap=0
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
            preview=$(cliphist list | awk -F '\t' -v id="$entry" '
                $1 == id { print substr($0, index($0, "\t") + 1); found = 1 }
                END { if (!found) exit 1 }
            ')
            mkdir -p -- "$pins_dir"
            temp_dir=$(mktemp -d "$pins_dir/.pin.XXXXXX")
            printf '%s' "$entry" | cliphist decode > "$temp_dir/data"
            printf '%s\n' "$preview" > "$temp_dir/preview"

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
