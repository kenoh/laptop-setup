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
	xset s 1770 1800  # with xss-lock: notifier, then locker timeouts (not adding up)

	setxkbmap us,sk ,qwerty grp:ctrls_toggle,ctrl:nocaps,compose:paus
	xmodmap -e "keycode 37="  # disable Left Control
	xmodmap -e "pointer = 1 2 3 4 5 6 7 0 0"  # disable Back/Forward mouse scrollwheel buttons

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
