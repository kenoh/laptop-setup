#!/bin/bash

turn_capslock_off() {
    xset -q | grep "Caps Lock: *on" \
	&& xdotool key Caps_Lock
}

xinputTouchpadId() {
    devs="$(xinput list --short | grep -i synaptics | grep -Po '(?<=id=)[[:digit:]]*')"
    if [ $(echo "$devs" | wc -l) -eq 1 ]; then
		echo "$devs" | tr -d '\n'
    else
		return 1
    fi
}

main() {
	xset dpms 1800 7200 28800
	xset s 270 300  # with xss-lock: notifier, then locker timeouts (not adding up)

	setxkbmap us,sk ,qwerty grp:ctrls_toggle,ctrl:nocaps,compose:paus
	xmodmap -e "keycode 37="

	if which synclient >/dev/null 2>&1; then
		synclient TapButton1=1
		synclient TapButton2=3
		synclient TapButton3=2
		synclient PalmDetect=1
		#synclient TouchpadOff=1
	else
		touchpadSet() { xinput set-prop $(xinputTouchpadId) "$@" ; }
		touchpadSet 'libinput Tapping Enabled' --type=int --format=8 1
	fi

	turn_capslock_off
}

main
