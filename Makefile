PLC_HOSTNAME     ?= 192.168.2.232
PLC_NET_ID       ?= 192.168.2.232
PLC_USERNAME     ?= Administrator
SSH_KEY_FILENAME ?= $(shell pwd)/tcbsd_key_rsa

export PLC_HOSTNAME
export PLC_NET_ID
export PLC_USERNAME
export SSH_KEY_FILENAME

all: ssh-setup run-playbook

ssh-setup:
	if [ ! -f "$(SSH_KEY_FILENAME)" ]; then \
		ssh-keygen -t rsa -f "$(SSH_KEY_FILENAME)"; \
	fi
	ssh-copy-id -i "$(SSH_KEY_FILENAME)" "$(PLC_USERNAME)@$(PLC_HOSTNAME)"
	ssh -i "$(SSH_KEY_FILENAME)" "$(PLC_USERNAME)@$(PLC_HOSTNAME)" 'echo "Successfully logged in with the key to $(PLC_HOSTNAME)"'

run-playbook:
	ansible-playbook tcbsd-setup-playbook.yaml -i host_inventory.yaml

.PHONY: all ssh-setup run-playbook
