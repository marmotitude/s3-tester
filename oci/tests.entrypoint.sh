#!/bin/bash

# setup profiles
echo "$PROFILES" > profiles.yaml

# rclone
RCLONE_CONFIG_PATH="$HOME/.config/rclone"
mkdir -p "$RCLONE_CONFIG_PATH"
gotpl -f profiles.yaml templates/rclone/rclone.conf -o "$RCLONE_CONFIG_PATH"

# aws-cli
AWS_CONFIG_PATH="$HOME/.aws"
mkdir -p "$AWS_CONFIG_PATH"
gotpl -f profiles.yaml templates/aws/credentials -o "$AWS_CONFIG_PATH"
gotpl -f profiles.yaml templates/aws/config -o "$AWS_CONFIG_PATH"

# mgc
profiles=$(dasel -f ./profiles.yaml -r yaml -s '.keys().join(" ")' | sed "s/[][]//g; s/'//g")
for profile in $profiles;do
  MGC_CONFIG_PATH="$HOME/.config/mgc/$profile/"
  mkdir -p $MGC_CONFIG_PATH
  dasel -f ./profiles.yaml -r yaml -s "$profile" > "./profile.$profile.yaml"
  gotpl -f "profile.$profile.yaml" templates/mgc/auth.yaml -o "$MGC_CONFIG_PATH"
  gotpl -f "profile.$profile.yaml" templates/mgc/cli.yaml -o "$MGC_CONFIG_PATH"
done
ls "$HOME/.config/mgc"

# run the main script
test.sh "$@"
