PLC_HOSTNAME     ?= 192.168.2.235
PLC_NET_ID       ?= $(PLC_HOSTNAME).1.1
PLC_USERNAME     ?= Administrator
SSH_KEY_FILENAME ?= $(shell pwd)/tcbsd_key_rsa
OUR_IP_ADDRESS   ?= $(shell ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | head -n 1)
OUR_NET_ID       ?= $(OUR_IP_ADDRESS).1.1

export PLC_HOSTNAME
export PLC_NET_ID
export PLC_USERNAME
export SSH_KEY_FILENAME

all: ssh-setup run-provision

ssh-setup:
	if [ ! -f "$(SSH_KEY_FILENAME)" ]; then \
		ssh-keygen -t rsa -f "$(SSH_KEY_FILENAME)"; \
	fi
	ssh-copy-id -i "$(SSH_KEY_FILENAME)" "$(PLC_USERNAME)@$(PLC_HOSTNAME)"
	ssh -i "$(SSH_KEY_FILENAME)" "$(PLC_USERNAME)@$(PLC_HOSTNAME)" 'echo "Successfully logged in with the key to $(PLC_HOSTNAME)"'

host_inventory.yaml: Makefile host_inventory.yaml.template
	envsubst < "host_inventory.yaml.template" > "$@"

run-bootstrap: host_inventory.yaml tcbsd-bootstrap-playbook.yaml
	ansible-playbook tcbsd-bootstrap-playbook.yaml -i host_inventory.yaml

run-provision: run-bootstrap host_inventory.yaml tcbsd-provision-playbook.yaml
	ansible-playbook tcbsd-provision-playbook.yaml -i host_inventory.yaml

add-route:
	echo "Your local IP is set as: $(OUR_IP_ADDRESS)"
	echo "(If using the auto-detection from the Makefile, it may be wrong. Sorry! Please set OUR_IP_ADDRESS specifically.)"
	if command -v ads-async &> /dev/null; then \
		echo "PLC information:"; \
		ads-async info "$(PLC_HOSTNAME)"; \
		ADS_ASYNC_LOCAL_IP="$(OUR_IP_ADDRESS)" ADS_ASYNC_LOCAL_NET_ID="$(OUR_NET_ID)" \
				ads-async get --add-route "$(PLC_HOSTNAME)" MAIN.bValue; \
	else \
		echo "No ads tools found to get PLC info / add route"; \
	fi

.PHONY: all ssh-setup run-provision run-bootstrap add-route
