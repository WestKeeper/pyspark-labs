#!/bin/bash

# Parse input parameters
DOCKER_CONFIG_PATH="docker_config"
DOCKER_IMAGE_TYPE=""
DOCKER_IMAGE_NAME=""
while getopts ":d:t:i:" opt; do
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
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

# Parse docker_config and fill out config as associative array
declare -A config
if [ ! -f "$DOCKER_CONFIG_PATH" ]; then
  echo "Unable to build docker image, docker config file $DOCKER_CONFIG_PATH does not exist"; exit 1
else
  while IFS= read -r line || [ -n "${line}" ]; do
    if [[ "$line" == "" ]] || [[ "$line" == \#* ]]; then
      continue
    fi

    IFS='=' read -r -a array <<< "$line"
    config["${array[0]}"]="${array[1]}"

  done < "$DOCKER_CONFIG_PATH"
fi

# Run docker build with configured parameters
USER_NAME_PARAMETER_NAME=user_name
WORKING_DIR_PARAMETER_NAME=working_dir

IMAGE_NAME_PARAMETER_NAME=image_name
DOCKERFILE_PATH_PARAMETER_NAME=dockerfile_path

FINAL_DOCKER_IMAGE_NAME="${config[$IMAGE_NAME_PARAMETER_NAME]}-${USER}"
if [ "$DOCKER_IMAGE_NAME" != "" ]; then
  FINAL_DOCKER_IMAGE_NAME="$DOCKER_IMAGE_NAME"
fi

docker_build_cmd="docker build "
docker_build_cmd+="--build-arg USER_NAME=${config[$USER_NAME_PARAMETER_NAME]} "
docker_build_cmd+="--build-arg USER_ID=$(id -u ${USER}) "
docker_build_cmd+="--build-arg GROUP_ID=$(id -g ${USER}) "
docker_build_cmd+="--build-arg WORKING_DIR=${config[$WORKING_DIR_PARAMETER_NAME]} "
docker_build_cmd+="-t $FINAL_DOCKER_IMAGE_NAME "
docker_build_cmd+="-f ${config[$DOCKERFILE_PATH_PARAMETER_NAME]} "
docker_build_cmd+="."

echo "$docker_build_cmd"
eval "$docker_build_cmd"
