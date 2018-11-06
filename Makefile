all:
	ansible-playbook --ask-become-pass -i inventory.txt --diff playbook.yml

check:
	ansible-playbook --ask-become-pass -i inventory.txt --diff --check playbook.yml

single:
	ansible-playbook --ask-become-pass -i inventory.txt --diff single.yml

single-check:
	ansible-playbook --ask-become-pass -i inventory.txt --diff --check single.yml

clean:
	git clean -Xf
