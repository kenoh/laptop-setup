#!/bin/bash
set -x

FN="test.yml"
FNR="test.retry"

test -f "$FN" && (
  echo "Found test.yml file. Is it yours? If so, remove it before running again. Thanks!"
  exit 1
)

cat > "$FN" <<EOF
---
- hosts: localhost
  become_user: root
  roles:
$(echo ${@} | sed 's/ /\n/g' | sed 's/^/    - /')
EOF

ansible-playbook --ask-become-pass -i inventory.txt --diff ${CHECK+--check} ${VERBOSE} "$FN"

rm "$FN" "$FNR"
