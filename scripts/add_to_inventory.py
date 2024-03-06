"""
Helper for adding new plc hosts to the inventory.
"""
from __future__ import annotations

import argparse
from pathlib import Path
from ruamel.yaml import YAML

yaml = None
_Inventory = dict[str, dict]


def get_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="add_to_inventory.py",
        description=__doc__,
    )
    parser.add_argument("hostname", type=str)
    parser.add_argument("--group", type=str, default="")
    return parser


def init_yaml():
    global yaml
    yaml = YAML(typ="rt")


def load_inventory(path: str | Path) -> _Inventory:
    if yaml is None:
        init_yaml()
    with Path(path).open("r") as fd:
        return yaml.load(fd)


def write_inventory(path: str | Path, inventory: _Inventory) -> None:
    if yaml is None:
        raise RuntimeError("Must load before dumping")
    with Path(path).open("w") as fd:
        fd.write("---\n")
        yaml.dump(
            inventory,
            fd,
        )


def host_in_inventory(hostname: str, inventory: _Inventory) -> bool:
    for dct in inventory.values():
        try:
            if hostname in dct["hosts"]:
                return True
        except KeyError:
            pass
    return False


def add_host_to_group(hostname: str, group: str, inventory: _Inventory) -> None:
    hosts_in_group = list(inventory[group]["hosts"])
    hosts_in_group.append(hostname)
    hosts_in_group.sort()
    inventory[group]["hosts"] = {name: None for name in hosts_in_group}


def get_group_options(inventory: _Inventory) -> list[str]:
    return [key for key in inventory if key not in ("plcs", "tcbsd_plcs")]


def main(hostname: str, group: str = "") -> int:
    inventory_path = Path(__file__).parent.parent / "inventory" / "plcs.yaml"
    inventory = load_inventory(path=inventory_path)
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
