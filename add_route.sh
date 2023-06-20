#!/usr/bin/env bash

if [ -z "$OUR_IP_ADDRESS" ]; then
  echo "This script is intended to be run from the Makefile as it expects a" 2>/dev/stderr
  echo "certain set of variables to be set in advance. Sorry!" 2>/dev/stderr
  exit 1
fi

echo "Your local IP is set as: ${OUR_IP_ADDRESS} (**)"
echo "PLC IP address:          ${PLC_IP}"
echo "Local AMS net ID:        ${OUR_NET_ID}"
echo "PLC username:            ${PLC_USERNAME}"
echo "PLC route name:          ${OUR_ROUTE_NAME}"
echo
echo "** If using the auto-detection from the Makefile, it may be wrong."
echo "   Please set OUR_IP_ADDRESS specifically before running this."
echo
read -p "Enter password for adding PLC route: " -rs PLC_PASSWORD ;
echo

set -e

if command -v adstool &> /dev/null; then
  echo "Found adstool, using it..."
  adstool "${PLC_IP}" --localams="${OUR_NET_ID}" --log-level=0 addroute \
    --addr="${OUR_IP_ADDRESS}" --netid="${OUR_NET_ID}" \
    --username="${PLC_USERNAME}" --password="${PLC_PASSWORD}" \
    --routename="${OUR_ROUTE_NAME}";
elif command -v ads-async &> /dev/null; then
  echo "Found ads-async, using it..."
  echo "PLC information:"
  ads-async info "${PLC_IP}"
  ADS_ASYNC_LOCAL_IP="${OUR_IP_ADDRESS}" ADS_ASYNC_LOCAL_NET_ID="${OUR_NET_ID}" \
      ads-async route --route-name "${OUR_ROUTE_NAME}" \
        --username "${PLC_USERNAME}" --password "${PLC_PASSWORD}" \
        "${PLC_IP}" "${OUR_NET_ID}" "${OUR_IP_ADDRESS}";
else
  echo "No ads tools found to get PLC info / add route"
fi
echo "Added a route to the PLC named ${OUR_ROUTE_NAME}:"
echo "  ${OUR_IP_ADDRESS} - ${OUR_NET_ID} <-> ${PLC_IP} ${PLC_NET_ID}"
