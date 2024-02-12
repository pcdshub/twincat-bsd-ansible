# This is the IP address of the PLC.
PLC_IP           ?=
PLC_HOSTNAME     ?= test-plc-01
PLC_NET_ID       ?= $(PLC_IP).1.1
PLC_USERNAME     ?= Administrator
PLC_HOST_VARS    = host_vars/$(PLC_HOSTNAME)/vars.yml
SSH_KEY_FILENAME ?= $(shell pwd)/tcbsd_key_rsa

# This auto-detects your local adapter's IP address. It may be completely wrong.
# Change it in your environment (OUR_IP_ADDRESS=... make) or replace the value
# after ?= with your IP.
OUR_IP_ADDRESS   ?= $(shell ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p' | head -n 1)
OUR_NET_ID       ?= $(OUR_IP_ADDRESS).1.1
OUR_ROUTE_NAME   ?= $(shell hostname -s)

export PLC_HOSTNAME
export PLC_IP
export PLC_NET_ID
export PLC_USERNAME
export OUR_IP_ADDRESS
export OUR_NET_ID
export OUR_ROUTE_NAME
export SSH_KEY_FILENAME

ifndef PLC_IP
$(error PLC_IP is not set. Set it to the PLC's IP address.)
endif
ifndef PLC_HOSTNAME
$(error PLC_HOSTNAME is not set.)
endif
ifndef OUR_IP_ADDRESS
$(warning OUR_IP_ADDRESS is not set. Will not be able to add route.)
endif

all: ssh-setup run-provision

clean:
	rm -f $(PLC_HOST_VARS)

ssh-setup:
	if [ ! -f "$(SSH_KEY_FILENAME)" ]; then \
		ssh-keygen -t rsa -f "$(SSH_KEY_FILENAME)"; \
	fi
	ssh-copy-id -i "$(SSH_KEY_FILENAME)" "$(PLC_USERNAME)@$(PLC_IP)"
	$(MAKE) ssh SSH_ARGS='echo "Successfully logged in with the key to $(PLC_IP)"'

ssh:
	ssh -i "$(SSH_KEY_FILENAME)" "$(PLC_USERNAME)@$(PLC_IP)" $(SSH_ARGS)

$(PLC_HOST_VARS): Makefile tcbsd-plc.yaml.template
	# This substitutes our local environment into ``host_inventory.yaml.template``
	# and writes ``host_inventory.yaml``
	@mkdir -p $(shell dirname "$@")
	envsubst < "tcbsd-plc.yaml.template" > "$@"

run-bootstrap: $(PLC_HOST_VARS) tcbsd-bootstrap-playbook.yaml
	ansible-playbook tcbsd-bootstrap-playbook.yaml --extra-vars "target=tcbsd_vms ansible_ssh_private_key_file=${SSH_KEY_FILENAME}"

run-provision: run-bootstrap tcbsd-provision-playbook.yaml
	ansible-playbook tcbsd-provision-playbook.yaml --extra-vars "target=tcbsd_vms ansible_ssh_private_key_file=${SSH_KEY_FILENAME}"

add-route:
	# NOTE: the add_route script lazily uses environment variables instead of
	# command-line arguments.
	bash add_route.sh

.PHONY: all clean ssh-setup ssh run-provision run-bootstrap add-route
