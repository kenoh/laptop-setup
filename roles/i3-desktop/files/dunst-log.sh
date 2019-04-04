#!/bin/bash
date="$(date +'%Y%m%dt%H%M%S')"
# format of the input: appname, summary, body, icon, urgency
echo "--- [$date] ($1) #$5 <<$2>> $3" >> ~/.k-dunst.log
