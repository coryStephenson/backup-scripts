#!/usr/bin/env bash

# Backup strategy and implementation found at: https://linuxconfig.org/how-to-create-incremental-backups-using-rsync-on-linux

# A script to perform incremental backups using rsync

# the set command is used to set or unset certain flags or settings within the shell environment
# set -o is used to specify option names
# errexit tells the shell to exit the script immediately if a command exits with a non-zero status
# nounset tells the shell to treat unset variables as an error when substituting
# pipefail says the return value of a pipeline is the status of the last command to exit with a non-zero status,
# or zero if no command exited with a non-zero status
# For more info on these options and more, type 'help set' at the terminal prompt

set -o errexit
set -o nounset
set -o pipefail

# You cannot change the value of readonly variables
readonly SOURCE_DIR="${HOME}"
readonly BACKUP_DIR="/mnt/data/backups"
readonly DATETIME="$(date '+%Y-%m-%d_%H:%M:%S')"
readonly BACKUP_PATH="${BACKUP_DIR}/inc_${DATETIME}"
readonly LATEST_LINK="${BACKUP_DIR}/latest"

# make directory, including parents
mkdir -p "${BACKUP_DIR}"

# remote sync - archive mode, increase verbosity
# --delete says delete extraneous files from destination directory
# --exclude says to exclude files
rsync -av --delete \
  "${SOURCE_DIR}/" \
  --link-dest="${LATEST_LINK}" \
  --exclude=".cache" \
  "${BACKUP_PATH}"

# Remove soft link that points to previous backup
rm -rf "${LATEST_LINK}"

# Create another soft link with the same name that points to the latest backup
ln -s "${BACKUP_PATH}" "${LATEST_LINK}"
