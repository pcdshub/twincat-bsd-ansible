"""
Helper for adding new plc hosts to the inventory.

Hosts must be in the inventory to be managed with the ansible scripts.
Hosts can be assigned a group for batch operations.
"""
from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any, Literal, Union

from ruamel.yaml import YAML

yaml = None
# The yaml has top-level group names as strings
# Each group will either have hosts or references to children groups in a hierarchy
# Elements within these sections are dicts, with the keys being the hostnames
# The sub-dict values either point to None or contain config options (Any)
# A group's hosts dict might be missing entirely if there are no hosts in that group
# In these cases, the sub-group is replaced by a None due to the yaml syntax
# Children groups will always be populated
# Unions are used explicitly for py39 compat, future doesn't apply to aliases
_Inventory = dict[
    str,
    Union[
        dict[
            Literal["hosts"],
            Union[
                dict[str, Any],
                None,
            ]
        ],
        dict[
            Literal["children"],
            dict[str, Any]
        ],
    ]
]


def get_parser() -> argparse.ArgumentParser:
    """Return the parser used for CLI argument parsing."""
    parser = argparse.ArgumentParser(
        prog="add_to_inventory.py",
        description=__doc__,
    )
    parser.add_argument("hostname", type=str)
    parser.add_argument("--group", type=str, default="")
    return parser


def init_yaml():
    """Setup a reusable global yaml instance for round-trip reading and writing."""
    global yaml
    yaml = YAML(typ="rt")


def load_inventory(path: str | Path) -> _Inventory:
    """Load the inventory from the inventory file."""
    if yaml is None:
        init_yaml()
    with Path(path).open("r") as fd:
        return yaml.load(fd)


def write_inventory(path: str | Path, inventory: _Inventory) -> None:
    """Write the updated inventory back to the inventory file."""
    if yaml is None:
        raise RuntimeError("Must load before dumping")
    with Path(path).open("w") as fd:
        fd.write("---\n")
        yaml.dump(
            inventory,
            fd,
        )


def host_in_inventory(hostname: str, inventory: _Inventory) -> bool:
    """Return True if hostname is in the inventory, and False otherwise."""
    for dct in inventory.values():
        try:
            if hostname in dct["hosts"]:
                return True
        except (KeyError, TypeError):
            pass
    return False


def add_host_to_group(hostname: str, group: str, inventory: _Inventory) -> None:
    """Add hostname to the inventory under the selected group."""
    group_dict = inventory[group]
    try:
        hosts_dict = group_dict["hosts"]
    except KeyError:
        raise ValueError(f"Group {group} is not a hosts group.")
    if hosts_dict is None:
        hosts_dict = {}
    hosts_in_group = list(hosts_dict)
    hosts_in_group.append(hostname)
    hosts_in_group.sort()
    inventory[group]["hosts"] = {
        name: hosts_dict.get(name, None) for name in hosts_in_group
    }


def get_group_options(inventory: _Inventory) -> list[str]:
    """Get a list of acceptable inventory options for group."""
    return [key for key in inventory if key not in ("plcs", "tcbsd_plcs")]


def main(hostname: str, group: str = "") -> int:
    inventory_path = Path(__file__).parent.parent / "inventory" / "plcs.yaml"
    inventory = load_inventory(path=inventory_path)
    if host_in_inventory(hostname=hostname, inventory=inventory):
        print(f"{hostname} already in inventory, skipping!")
        return 0
    options = get_group_options(inventory=inventory)
    text_options = "\n".join(options)
    while group not in options:
        print(f"Please select a group from the following options:\n{text_options}\n")
        group = input().strip()
    print(f"Adding {hostname} to group {group}")
    add_host_to_group(hostname=hostname, group=group, inventory=inventory)
    write_inventory(path=inventory_path, inventory=inventory)
    return 0


if __name__ == "__main__":
    parser = get_parser()
    args = parser.parse_args()
    exit(main(
        hostname=args.hostname,
        group=args.group,
    ))
