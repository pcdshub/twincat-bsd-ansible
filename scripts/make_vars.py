"""
Script to make a host-specific vars.yml from the tcbsd-plc.yaml.template

Includes the defaults for all variables as a commented-out section below,
for easy per-host reconfiguration.
"""
from __future__ import annotations

import argparse
import socket
from typing import Iterator
from pathlib import Path
from string import Template

from ruamel.yaml import YAML

_Inventory = dict[str, dict]


def get_parser() -> argparse.ArgumentParser:
    """Return the parser used for CLI argument parsing."""
    parser = argparse.ArgumentParser(
        prog="make_vars.py",
        description=__doc__,
    )
    parser.add_argument("hostname", type=str)
    return parser


def get_group(
    hostname: str,
    inventory_path: str | Path,
    groups_path: str | Path,
) -> str:
    """For a given hostname, get the name of the vars group it belongs to."""
    yaml = YAML()
    with Path(inventory_path).open("r") as fd:
        inventory_data = yaml.load(fd)
    group_options = [path.name for path in Path(groups_path).glob("*")]
    for group in group_options:
        if hostname in iter_child_hosts(inventory_data=inventory_data, group=group):
            return group
    raise RuntimeError(f"Did not find {hostname} in any vars groups!")


def iter_child_hosts(inventory_data: _Inventory, group: str) -> Iterator[str]:
    """Yield all the hostnames associated with a group."""
    group_data = inventory_data[group]
    hosts_dicts = group_data.get("hosts")
    if hosts_dicts is not None:
        for hostname in hosts_dicts:
            yield hostname
    child_dicts = group_data.get("children")
    if child_dicts is not None:
        for child_group in child_dicts:
            yield from iter_child_hosts(
                inventory_data=inventory_data,
                group=child_group,
            )


def get_netid(hostname: str) -> str:
    """Get the expected AMS netid for a given hostname."""
    ipaddr = socket.gethostbyname(hostname)
    return ipaddr + ".1.1"


def write_host_vars(
    hostname: str,
    host_vars_path: str | Path,
    group_vars_path: str | Path,
    template_path: str | Path,
) -> None:
    """Write the vars.yml file given the necessary information."""
    # Load the template, sub in the values
    with Path(template_path).open("r") as fd:
        template = Template(fd.read())
    host_vars_text = template.substitute(
        PLC_IP=hostname,
        PLC_NET_ID=get_netid(hostname=hostname),
    )
    # Load the group vars, prepend with comment
    with Path(group_vars_path).open("r") as fd:
        group_vars_lines = ["#" + line for line in fd.read().splitlines()[1:]]
    # Write the new file
    with Path(host_vars_path).open("w") as fd:
        fd.write(host_vars_text)
        fd.write(
            "\n"
            "# Uncomment any setting below and change it "
            "to override a default setting."
            "\n"
        )
        fd.write("\n".join(group_vars_lines))
        fd.write("\n")


def main(hostname: str) -> int:
    repo_root = Path(__file__).parent.parent
    inventory_path = repo_root / "inventory" / "plcs.yaml"
    groups_path = repo_root / "group_vars"
    group = get_group(
        hostname=hostname,
        inventory_path=inventory_path,
        groups_path=groups_path,
    )
    group_vars_path = groups_path / group / "vars.yml"
    template_path = repo_root / "tcbsd-plc.yaml.template"
    host_vars_path = repo_root / "host_vars" / hostname / "vars.yml"
    host_vars_path.parent.mkdir(exist_ok=True)
    write_host_vars(
        hostname=hostname,
        host_vars_path=host_vars_path,
        group_vars_path=group_vars_path,
        template_path=template_path,
    )
    print(
        f"Created {host_vars_path}, "
        "please edit this as needed for plc-specific settings."
    )
    return 0


if __name__ == "__main__":
    parser = get_parser()
    args = parser.parse_args()
    exit(main(hostname=args.hostname))
