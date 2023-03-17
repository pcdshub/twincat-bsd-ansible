# This is the IP address of the PLC.
PLC_IP           ?=
PLC_HOSTNAME     ?= my-plcname
PLC_NET_ID       ?= $(PLC_IP).1.1
PLC_USERNAME     ?= Administrator
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

ssh-setup:
	if [ ! -f "$(SSH_KEY_FILENAME)" ]; then \
		ssh-keygen -t rsa -f "$(SSH_KEY_FILENAME)"; \
	fi
	ssh-copy-id -i "$(SSH_KEY_FILENAME)" "$(PLC_USERNAME)@$(PLC_IP)"
	$(MAKE) ssh SSH_ARGS='echo "Successfully logged in with the key to $(PLC_IP)"'

ssh:
	ssh -i "$(SSH_KEY_FILENAME)" "$(PLC_USERNAME)@$(PLC_IP)" $(SSH_ARGS)

host_inventory.yaml: Makefile host_inventory.yaml.template
	# This substitutes our local environment into ``host_inventory.yaml.template``
	# and writes ``host_inventory.yaml``
	envsubst < "host_inventory.yaml.template" > "$@"

run-bootstrap: host_inventory.yaml tcbsd-bootstrap-playbook.yaml
	ansible-playbook tcbsd-bootstrap-playbook.yaml -i host_inventory.yaml

run-provision: run-bootstrap host_inventory.yaml tcbsd-provision-playbook.yaml
	ansible-playbook tcbsd-provision-playbook.yaml -i host_inventory.yaml

add-route:
	@echo "Your local IP is set as: $(OUR_IP_ADDRESS)"
	@echo "(If using the auto-detection from the Makefile, it may be wrong. Sorry! Please set OUR_IP_ADDRESS specifically.)"
	read -p "Enter password for adding PLC route: " -rs PLC_PASSWORD ; \
	echo ""; \
	if command -v adstool &> /dev/null; then \
		echo "Found adstool, using it..."; \
		adstool "$(PLC_IP)" --localams="$(OUR_NET_ID)" --log-level=0 addroute \
			--addr="$(OUR_IP_ADDRESS)" --netid="$(OUR_NET_ID)" \
			--username="$(PLC_USERNAME)" --password="$${PLC_PASSWORD}" \
			--routename="$(OUR_ROUTE_NAME)" ; \
	elif command -v ads-async &> /dev/null; then \
		echo "Found ads-async, using it..."; \
		echo "PLC information:"; \
		ads-async info "$(PLC_IP)"; \
		ADS_ASYNC_LOCAL_IP="$(OUR_IP_ADDRESS)" ADS_ASYNC_LOCAL_NET_ID="$(OUR_NET_ID)" \
				ads-async route --route-name "$(OUR_ROUTE_NAME)" \
					--username "$(PLC_USERNAME)" --password "$${PLC_PASSWORD}" \
					"$(PLC_IP)" "$(OUR_NET_ID)" "$(OUR_IP_ADDRESS)"; \
	else \
		echo "No ads tools found to get PLC info / add route"; \
	fi
	@echo "Added a route to the PLC named $(OUR_ROUTE_NAME):"
	@echo "  $(OUR_IP_ADDRESS) - $(OUR_NET_ID) <-> $(PLC_IP) $(PLC_NET_ID)"

.PHONY: all ssh-setup ssh run-provision run-bootstrap add-route
