#!/bin/bash

# Replace S3 configs
# ------------------
# Based on a generic profiles.yaml file, generate new config files for aws, rclone and mgc cli clients

RCLONE_CONFIG_PATH="$HOME/.config/rclone"
AWS_CONFIG_PATH="$HOME/.aws"
MGC_CONFIG_PATH="$HOME/.config/mgc"
profiles=$(dasel -f ./profiles.yaml -r yaml -s '.keys().join(" ")' | sed "s/[][]//g; s/'//g")
backup_id=$(date +%s)

# Function to backup existing files or folders
backup_existing() {
    local source_path=$1
    if [ -e "$source_path" ]; then
        local backup_path="${source_path}.${backup_id}.bkp"
        cp -r "$source_path" "$backup_path"
        echo "Backed up $source_path to $backup_path"
    fi
}

# Backup existing files
backup_existing "$RCLONE_CONFIG_PATH/rclone.conf"
backup_existing "$AWS_CONFIG_PATH/credentials"
backup_existing "$AWS_CONFIG_PATH/config"

for profile in $profiles; do
    MGC_PROFILE_PATH="$MGC_CONFIG_PATH/$profile"
    backup_existing "$MGC_PROFILE_PATH"
done

# Create new configs
mkdir -p "$RCLONE_CONFIG_PATH"
gotpl -f profiles.yaml templates/rclone/rclone.conf -o "$RCLONE_CONFIG_PATH"

mkdir -p "$AWS_CONFIG_PATH"
gotpl -f profiles.yaml templates/aws/credentials -o "$AWS_CONFIG_PATH"
gotpl -f profiles.yaml templates/aws/config -o "$AWS_CONFIG_PATH"

mkdir -p "$MGC_CONFIG_PATH"
for profile in $profiles; do
    MGC_PROFILE_PATH="$MGC_CONFIG_PATH/$profile"
    MGC_PROFILE_YAML="./profile.$profile.yaml"
    mkdir -p "$MGC_PROFILE_PATH"
    dasel -f ./profiles.yaml -r yaml -s "$profile" > "$MGC_PROFILE_YAML"
    gotpl -f "$MGC_PROFILE_YAML" templates/mgc/auth.yaml -o "$MGC_PROFILE_PATH"
    gotpl -f "$MGC_PROFILE_YAML" templates/mgc/cli.yaml -o "$MGC_PROFILE_PATH"
    rm "$MGC_PROFILE_YAML"
done

