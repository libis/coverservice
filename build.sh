#!/bin/bash

if [ ! -f ".env" ]; then
   echo "Please create an .env file with a SERVICE, REGISTRY, NAMESPACE, VERSION and PLATFORM parameter"
   echo "
         SERVICE=my-api
         REGISTRY=registry.docker.libis.be
         NAMESPACE=my-project
         PLATFORM=linux/amd64"
   exit 1
fi

source .env

if [ -z $REGISTRY ]; then
   echo "Please set REGISTRY in .env"
   exit 1
fi

if [ -z $SERVICE ]; then
   echo "Please set SERVICE in .env"
   exit 1
fi

if [ -z $NAMESPACE ]; then
   echo "Please set NAMESPACE in .env"
   exit 1
fi

if [ -z $VERSION ]; then
   echo "Please set VERSION in .env"
   echo 'Using "latest"'
   VERSION=latest
fi

if [ -z $PLATFORM ]; then
   echo "Please set $PLATFORM in .env can be one of linux/amd64, linux/arm64"
   ARCH=${uname -m}
   echo "Using linux/$ARCH"
   PLATFORM="linux/$ARCH"
fi

function remove_config_tgz {
  if [ -f "./config.tgz" ]; then
    echo "Remove previous config.tgz package"
    rm -f ./config.tgz
  fi
}

function create_config_tgz {
  remove_config_tgz
  if [ -d "./config" ]; then
    echo "Creating config.tgz package"
    tar --format=ustar -zcvf ./config.tgz ./config/*
  fi
}

function build {
   create_config_tgz
   echo "Building $SERVICE for $PLATFORM"
   docker buildx build --platform=$PLATFORM --build-arg VERSION=$VERSION -f Dockerfile --tag $REGISTRY/$NAMESPACE/$SERVICE:$VERSION --tag $REGISTRY/$NAMESPACE/$SERVICE:latest --load .
   remove_config_tgz
}

function push {
   create_config_tgz
   echo "Building/Pushing $SERVICE for $PLATFORM"
   docker buildx build --platform=$PLATFORM --build-arg VERSION=$VERSION -f Dockerfile --tag $REGISTRY/$NAMESPACE/$SERVICE:$VERSION --tag $REGISTRY/$NAMESPACE/$SERVICE:latest --push .
   remove_config_tgz
}

case $1 in
"push")
  push
  ;;
*)
  build
  ;;
esac

echo
echo
if [ -z "$DEBUG" ]; then
   echo "docker run $NAMESPACE/$SERVICE:$VERSION"
else
   echo "docker run -p 1234:1234 -e DEBUG=1 $NAMESPACE/$SERVICE:$VERSION"
fi

