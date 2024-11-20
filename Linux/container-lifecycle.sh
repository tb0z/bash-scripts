#!/bin/bash

# Dependencies #
# - packages
# -- podman
# -- skopeo
# - registry.conf

# FUNCTIONS #

log-crit() {
  while IFS='' read -r line;
      do echo $(date +'%b %e %H:%M:%S') $(hostname): Lifecycle Script:crit: $line >> /var/log/lifecycle_$CONTAINER\.log; 
  done;
};

# LOCAL VARS #
REPO=""
IMAGE=""
TAG=""
CONTAINER=""
ARGS=""
#REPO="docker://registry.access.redhat.com"
#IMAGE="ubi9/httpd-24"
#TAG="latest"
#CONTAINER="httpd-24_bootstrap-wcs"
#ARGS="-p 80:8080 -v /opt/http-content/:/var/www/html/:Z --name"

# GLOBAL VARS #
LATEST_VER=$(skopeo inspect $REPO/$IMAGE 2> >(log-crit) | grep Digest | head -n 1 |  awk '{print $2}' | tr -d [:punct:])  
CURRENT_VER=$(podman image inspect $IMAGE 2> >(log-crit) | grep Digest | head -n 1 | awk '{print $2}' | tr -d [:punct:])

# VARS VALIDATION #
if [ -z $LATEST_VER ]; then
    echo $(date +'%b %e %H:%M:%S') $(hostname): Lifecycle Script:err: GLOBAL VARS - LATEST_VER undefined - Please check connectivity to repository >> /var/log/lifecycle_$CONTAINER\.log
    exit 1;
fi

if [ -z $IMAGE ]; then
    echo $(date +'%b %e %H:%M:%S') $(hostname): Lifecycle Script:err: LOCAL VARS - IMAGE undefined - Please set in LOCAL VARS >> /var/log/lifecycle_$CONTAINER\.log
    exit 1;
fi

if [ -z $CONTAINER ]; then
    echo $(date +'%b %e %H:%M:%S') $(hostname): Lifecycle Script:err: LOCAL VARS - CONTAINER undefined - Please set in LOCAL VARS >> /var/log/lifecycle_$CONTAINER\.log
    exit 1;
fi

if [ -z "$ARGS" ]; then
    echo $(date +'%b %e %H:%M:%S') $(hostname): Lifecycle Script:warn: LOCAL VARS - ARGS undefined using default NULL >> /var/log/lifecycle_$CONTAINER\.log
fi

if [ -z $REPO ]; then
    echo $(date +'%b %e %H:%M:%S') $(hostname): Lifecycle Script:warn: LOCAL VARS - REPO undefined using default docker://registry.access.redhat.com >> /var/log/lifecycle_$CONTAINER\.log
fi

if [ -z $TAG ]; then
    echo $(date +'%b %e %H:%M:%S') $(hostname): Lifecycle Script:warn: LOCAL VARS - TAG undefined using default latest >> /var/log/lifecycle_$CONTAINER\.log
fi

# SET DEFAULT IF UNDEFINED #
if [ -z $CURRENT_VER ]; then
    CURRENT_VER="0"
fi

if [ -z "$ARGS" ]; then
    ARGS=""
fi

if [ -z $REPO ]; then
    REPO="docker://registry.access.redhat.com"
fi

if [ -z $TAG ]; then
    TAG="latest"
fi

# Version check based on image Digest
if [ $CURRENT_VER != $LATEST_VER ]; then

    # Digests do not match - redeploy using :latest tag
    podman stop $CONTAINER 2> >(log-crit)
    podman rm $CONTAINER 2> >(log-crit)
    podman image rm $IMAGE:$TAG 2> >(log-crit)
    podman pull $REPO/$IMAGE:$TAG
    podman run -d $ARGS $CONTAINER $IMAGE:$TAG

    # Update log status: Updated
    echo $(date +'%b %e %H:%M:%S') $(hostname): Lifecycle Script:info: $CONTAINER has been updated from Digest $CURRENT_VER to $LATEST_VER >> /var/log/lifecycle_$CONTAINER\.log

  else

    # Update log status: Up-to-Date  
    echo $(date +'%b %e %H:%M:%S') $(hostname): Lifecycle Script:info: $CONTAINER is Up-to-Date >> /var/log/lifecycle_$CONTAINER\.log

fi
