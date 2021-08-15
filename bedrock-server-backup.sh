#!/bin/bash

UNIT=bedrock-server
BEDROCK_STDIN=/run/${UNIT}.stdin
MINECRAFT_HOME=/var/lib/minecraft
BEDROCK_HOME=${MINECRAFT_HOME}/${UNIT}
BACKUP_DIR=${MINECRAFT_HOME}/backup/worlds/`date +"%Y%m%d_%H%M%S"`

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

echo "Directory: ${BACKUP_DIR}, Files: ${backup_targets[@]}"

# Remove old backups
find ${MINECRAFT_HOME}/backup/worlds/* -maxdepth 0 -mtime +30 | xargs rm -rf
