#!/bin/bash
set -e
set -x

FN="test.yml"
FNR="test.retry"

test -f "$FN" && exit 1

cat > "$FN" <<EOF
---
- hosts: localhost
  become: yes
  roles:
$(echo ${@} | sed 's/ /\n/g' | sed 's/^/    - /')
EOF

ansible-playbook --ask-become-pass -i inventory.txt --diff ${CHECK+--check} "$FN" \
	|| rm "$FN" "$FNR" && exit 1

rm "$FN"