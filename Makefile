all:
	ansible-playbook --ask-become-pass -i inventory.txt --diff playbook.yml

check:
	ansible-playbook --ask-become-pass -i inventory.txt --diff --check playbook.yml

clean:
	git clean -Xf
