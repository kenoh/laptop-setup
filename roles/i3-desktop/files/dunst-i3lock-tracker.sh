#!/bin/bash
pgrep -x dunst &>/dev/null || exit 101
which i3lock &>/dev/null || exit 102

while true; do
    pgrep -x i3lock &>/dev/null \
	&& killall -SIGUSR1 dunst \
	    || killall -SIGUSR2 dunst
    sleep 5
done
