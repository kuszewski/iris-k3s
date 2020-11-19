#!/bin/bash
# THIS SCRIPT WILL FAIL if you do not supply the correct YOUR USERNAME and YOUR TOKEN below
#
# make sure to get the username and token from https://containers.intersystems.com

kubectl create secret docker-registry intersystems-container-registry-secret --docker-server=https://containers.intersystems.com --docker-username=<YOUR USERNAME> --docker-password='<YOUR TOKEN>'

