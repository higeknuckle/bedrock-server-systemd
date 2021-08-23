#!/bin/bash

UNIT=bedrock-server
BEDROCK_STDIN=/run/${UNIT}.stdin
MINECRAFT_HOME=/var/lib/minecraft
BEDROCK_HOME=${MINECRAFT_HOME}/${UNIT}
BACKUP_DIR=${MINECRAFT_HOME}/backup/worlds/`date +"%Y%m%d_%H%M%S"`
BACKUP_REMAIN_DAYS=3

# Count online players
DATE=`date +"%Y-%m-%d %H:%M:%S"`
echo "list" > ${BEDROCK_STDIN}
sleep 1
COUNT=`journalctl -u ${UNIT}.service -q --since="${DATE}" | grep -oP '(?<=There are )\d+(?=\/\d+ players online:)'`
if [ ${COUNT} -eq 0 ]; then
  echo "There is no player online. Getting the latest backup and deleting old is omitted."
  exit 0
fi

# Backup
mkdir -p ${BACKUP_DIR}

DATE=`date +"%Y-%m-%d %H:%M:%S"`
echo "save hold" > ${BEDROCK_STDIN}

while true; do
  echo "save query" > ${BEDROCK_STDIN}
  sleep 1
  journalctl -u ${UNIT}.service -q --since="${DATE}" > ${BACKUP_DIR}/journal.out
  if grep -q 'Data saved. Files are now ready to be copied.' ${BACKUP_DIR}/journal.out; then
    break
  fi
  if grep -q 'A previous save has not been completed.' ${BACKUP_DIR}/journal.out; then
    echo "Backup aborted due to invalid state."
    exit 101
  fi
  sleep 1
done;

hit=false
while read LINE; do
  if "${hit}"; then
    backup_targets=( `echo ${LINE} | awk -F ": " '{print $2}' | tr -d ","` )
    break
  fi
  if echo ${LINE} | grep -q 'Data saved. Files are now ready to be copied.'; then
    hit=true
  fi
done < ${BACKUP_DIR}/journal.out

cd ${BEDROCK_HOME}/worlds
for target in "${backup_targets[@]}"
do
  target=( `echo ${target} | tr ":" " "` )
  # echo "file: ${target[0]}, size: ${target[1]}"
  cp --parents ${target[0]} ${BACKUP_DIR}
  truncate -s ${target[1]} ${BACKUP_DIR}/${target[0]}
done
cd - >/dev/null

echo "save resume" > ${BEDROCK_STDIN}

echo "Backup finished. Directory: ${BACKUP_DIR}, Count: ${#backup_targets[@]}, Files: ${backup_targets[@]}"

# Delete old backups
find ${MINECRAFT_HOME}/backup/worlds/* -maxdepth 0 -mtime +${BACKUP_REMAIN_DAYS} | xargs rm -rf
