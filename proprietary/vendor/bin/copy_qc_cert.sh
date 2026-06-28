#!/vendor/bin/sh

SCRIPT_NAME="copy_qc_cert.sh"
CONFIG_FILE="/vendor/etc/copy_qc_cert.conf"

# Function to read a value from the config file
get_config_value() {
    local section=$1
    local key=$2
    awk -F' *= *' -v section="[$section]" -v key="$key" '
    $0 == section { found_section=1 }
    found_section && $1 == key { print $2; exit }
    ' "$CONFIG_FILE"
}

debug() {
    echo "Debug: $*"
}

notice() {
    echo "Debug: $*"
    echo "$SCRIPT_NAME: $*" > /dev/kmsg
}

reinstall_cert() {
    local src=$1
    local dest=$2
    local current_md5="none"
    local src_md5="none"

    # Check if source file exists; if not, log a warning and exit the function
    if [ ! -f "$src" ]; then
        notice "WARNING: Source file $src does not exist. Skipping installation for $dest."
        return
    fi

    if [ -f "$src" ]; then
        src_md5=$(md5sum "$src" | cut -d" " -f1)
    fi

    if [ -f "${dest}.inst" ]; then
        current_md5=$(md5sum "${dest}.inst" | cut -d" " -f1)
    fi

    debug "MD5 comparison - src: $src_md5, dest: $current_md5"

    if [ "$src_md5" == "none" ] && [ "$current_md5" == "none" ]; then
        notice "Both source and destination files are missing for $dest. Skipping installation."
    elif [ "$src_md5" != "$current_md5" ]; then
        debug "MD5 mismatch, reinstalling $dest"
        rm -f "${dest}.inst"
        cp "$src" "$dest"
        if [ "$?" == "0" ]; then
            notice "Successfully copied $src to $dest"
        else
            notice "Failed to copy $src to $dest"
        fi
    else
        notice "$dest.inst is already up to date"
    fi
}

# Read all sections from the config file
sections=$(awk -F'[][]' '/\[/{print $2}' "$CONFIG_FILE")

# Loop through each section and process the certificates
for section in $sections; do
    echo "-----------------------------------------------"

    SRC=$(get_config_value "$section" "SRC")
    DEST=$(get_config_value "$section" "DEST")
    debug "Processing section: $section, SRC: $SRC, DEST: $DEST"

    if [ -n "$SRC" ] && [ -n "$DEST" ]; then
        debug "Start reinstalling $section cert"
        reinstall_cert "$SRC" "$DEST"
    fi
    echo "-----------------------------------------------"
done
