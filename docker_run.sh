#!/bin/bash

# Parse input parameters
DOCKER_CONFIG_PATH="docker_config"
DOCKER_IMAGE_TYPE=""
DOCKER_IMAGE_NAME=""
DOCKER_MOUNT=0
while getopts ":d:t:i:m:" opt; do
  case $opt in
    d) docker_config_path="$OPTARG"
      if [ "$docker_config_path" != "" ]; then
        DOCKER_CONFIG_PATH="$docker_config_path"
      fi
    ;;
    t) docker_image_type="$OPTARG"
      if [ "$docker_image_type" != "" ]; then
        DOCKER_IMAGE_TYPE="$docker_image_type"
      fi
    ;;
    i) docker_image_name="$OPTARG"
      if [ "$docker_image_name" != "" ]; then
        DOCKER_IMAGE_NAME="$docker_image_name"
      fi
      ;;
    m) docker_mount="$OPTARG"
      if [ "$docker_mount" != "" ]; then
        DOCKER_MOUNT="$docker_mount"
      fi
      ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Parse docker_config and fill out config as associative array
declare -A config
if [ ! -f "$DOCKER_CONFIG_PATH" ]; then
  echo "Unable to run dev docker container, docker config file $DOCKER_CONFIG_PATH does not exist"; exit 1
else
  while IFS= read -r line || [ -n "${line}" ]; do
    if [[ "$line" == "" ]] || [[ "$line" == \#* ]]; then
      continue
    fi

    IFS='=' read -r -a array <<< "$line"
    config["${array[0]}"]="${array[1]}"

  done < "$DOCKER_CONFIG_PATH"
fi

WORKING_DIR_PARAMETER_NAME=working_dir
HOST_DIR_TO_MOUNT_PARAMETER_NAME=host_dir_to_mount
CONTAINER_DIR_TO_MOUNT_PARAMETER_NAME=CONTAINER_DIR_TO_MOUNT_PARAMETER_NAME

CONTAINER_NAME_PARAMETER_NAME=container_name
CONTAINER_HOSTNAME_PARAMETER_NAME=container_hostname
IMAGE_NAME_PARAMETER_NAME=image_name

JUPYTER_PORT_PARAMETER_NAME=jupyter_port

FINAL_DOCKER_IMAGE_NAME="${config[$IMAGE_NAME_PARAMETER_NAME]}-${USER}"
if [ "$DOCKER_IMAGE_NAME" != "" ]; then
  FINAL_DOCKER_IMAGE_NAME="$DOCKER_IMAGE_NAME"
fi

FINAL_JUPYTER_PORT="${config[$JUPYTER_PORT_PARAMETER_NAME]}"
if [ "$JUPYTER_PORT" != "" ]; then
    FINAL_JUPYTER_PORT="$JUPYTER_PORT"
fi

docker_run_cmd="docker run "
docker_run_cmd+="-u $(id -u):$(id -g) "

docker_run_cmd+="--mount type=bind,source=$(pwd),destination=${config[$WORKING_DIR_PARAMETER_NAME]} "
if [ $DOCKER_MOUNT -eq 1 ]; then
  docker_run_cmd+="--mount type=bind,source=${config[$HOST_DIR_TO_MOUNT_PARAMETER_NAME]},destination=${config[$CONTAINER_DIR_TO_MOUNT_PARAMETER_NAME]} "
fi
docker_run_cmd+="-it "
docker_run_cmd+="--rm "
docker_run_cmd+="--name ${config[$CONTAINER_NAME_PARAMETER_NAME]}-${USER} "
docker_run_cmd+="-h ${config[$CONTAINER_HOSTNAME_PARAMETER_NAME]} "
docker_run_cmd+="-p $FINAL_JUPYTER_PORT:$FINAL_JUPYTER_PORT "
docker_run_cmd+="$FINAL_DOCKER_IMAGE_NAME "

echo "$docker_run_cmd"
eval "$docker_run_cmd"
