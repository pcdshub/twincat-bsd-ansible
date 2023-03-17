#!/usr/bin/python

from __future__ import absolute_import, division, print_function

import socket

import lxml
import lxml.etree
from ansible.module_utils.basic import AnsibleModule

__metaclass__ = type

# NOTE to self: this needs to remain Python 2 compatible! Type hints :(


DOCUMENTATION = r"""
---
module: tcbsd_route

short_description: Manage TwinCAT/BSD routes

version_added: "1.0.0"

description: Ensure routes are in StaticRoutes.xml in TwinCAT/BSD.

options:
    file:
        description:
            - Location of StaticRoutes.xml file to be changed.  Defaults to
            - the system-level one.
        required: false
        type: str
    state:
        description:
            - "present" to add/update routes; "absent" to remove routes
        required: false
        type: bool
    routes:
        description:
            - List of routes to add.
        required: true
        type: list

author:
    - klauer (@klauer)
"""

EXAMPLES = r"""
- name: Add routes to the system
  tcbsd_route:
    state: present
    routes:
      - name: test
        address: 1.1.1.2
        net_id: 1.1.1.2.1.1
        type: TCP_IP

- name: Remove routes from the system
  tcbsd_route:
    state: absent
    routes:
      - name: test
        address: 1.1.1.2
        net_id: 1.1.1.2.1.1
        type: TCP_IP

- name: Add routes to the system from the inventory
  tcbsd_route:
    state: present
    routes: "{{ tc_routes }}

- name: Add routes to an arbitrary file for testing
  tcbsd_route:
    file: /home/Administrator/test.xml
    state: present
    routes: "{{ tc_routes }}
"""

RETURN = r"""
routes_added:
    description: Number of routes added
    type: int
    returned: always
    sample: 0
routes_modified:
    description: Number of routes modified
    type: int
    returned: always
    sample: 0
routes_removed:
    description: Number of routes removed
    type: int
    returned: always
    sample: 0
routes_before:
    description: Number of routes before the module ran
    type: int
    returned: always
    sample: 0
routes_after:
    description: Number of routes after the module ran
    type: int
    returned: always
    sample: 0
message:
    description: Summary message
    type: str
    returned: always
    sample: ''
"""


class Route(object):
    def __init__(self, name, address, net_id="", type="", flags=""):
        if not net_id:
            net_id = "%s.1.1" % (hostname_to_ip_address(address),)
        self.name = name
        self.address = address
        self.net_id = net_id
        self.type_ = type or "TCP_IP"
        self.flags = flags or "64"

    def validate(self):
        assert self.name, "Name not set"
        assert self.address, "Address not set"
        assert self.net_id, "Net ID not set"

    def __eq__(self, other):
        if not isinstance(other, Route):
            return False

        return (
            other.name == self.name and
            other.address == self.address and
            other.net_id == self.net_id and
            other.type_ == self.type_ and
            other.flags == self.flags
        )

    @classmethod
    def from_xml_element(cls, element):
        def text_by_tag(tag, default=""):
            try:
                return element.xpath(tag)[0].text
            except IndexError:
                return default

        return cls(
            name=text_by_tag("Name"),
            address=text_by_tag("Address"),
            net_id=text_by_tag("NetId"),
            type=text_by_tag("Type"),
            flags=text_by_tag("Flags"),
        )

    def to_xml_element(self):
        self.validate()
        route = lxml.etree.Element("Route")
        name = lxml.etree.Element("Name")
        address = lxml.etree.Element("Address")
        net_id = lxml.etree.Element("NetId")
        type_ = lxml.etree.Element("Type")
        flags = lxml.etree.Element("Flags")
        name.text = str(self.name)
        address.text = str(self.address)
        net_id.text = str(self.net_id)
        type_.text = str(self.type_)
        flags.text = str(self.flags)
        route.extend([name, address, net_id, type_, flags])
        return route

    def __str__(self):
        return "Route %r (%s AMS Net ID %s via %s)" % (
            self.name,
            self.address,
            self.net_id,
            self.type_,
        )


def hostname_to_ip_address(hostname):
    return socket.gethostbyname(hostname)


def load_routes_from_file(filename):
    with open(filename, "rb") as fp:
        routes = lxml.etree.fromstring(fp.read())

    return [
        Route.from_xml_element(route)
        for route in routes.xpath("/TcConfig/RemoteConnections/Route")
    ]


def routes_to_xml(routes):
    tc_config = lxml.etree.Element(
        "TcConfig", nsmap={"xsi": "http://www.w3.org/2001/XMLSchema-instance"}
    )
    remote_connections = lxml.etree.Element("RemoteConnections")
    tc_config.append(remote_connections)

    for route in routes:
        remote_connections.append(route.to_xml_element())
    return tc_config


def save_routes_to_file(filename, routes):
    tc_config = routes_to_xml(routes)
    # NOTE: TCBSD writes tabs here; so let's conform
    lxml.etree.indent(tc_config, space="\t")
    xml_contents = lxml.etree.tostring(
        tc_config,
        xml_declaration=True,
        pretty_print=True,
        encoding="UTF-8",

    )
    with open(filename, "wb") as fp:
        fp.write(xml_contents)


def find_matching_routes(routes, route):
    for existing in routes:
        if (
            existing.name == route.name
            or existing.net_id == route.net_id
            or existing.address == route.address
        ):
            yield existing


def ensure_route_exists(routes, new_route):
    """
    Ensure a route exists - updating existing ones if required.

    Returns
    -------
    dict
        Route changes (added, removed, modified)
    """
    result = dict(
        routes_added=0,
        routes_removed=0,
        routes_modified=0,
    )
    existing = list(find_matching_routes(routes, new_route))
    if len(existing) == 0:
        # No existing routes. Easy - add the new one.
        routes.append(new_route)
        result["routes_added"] = 1
        return result

    # Existing route(s).  Pick the one with a matching name (if any) and
    # discard the rest.
    matching_by_name = [rt for rt in existing if rt.name == new_route.name]
    if len(matching_by_name) > 0:
        keep_route = matching_by_name[0]
    else:
        keep_route = None
        result["routes_added"] += 1
        routes.append(new_route)

    for rt in existing:
        if rt is keep_route:
            if rt != new_route:
                result["routes_modified"] += 1
                rt.name = new_route.name
                rt.address = new_route.address
                rt.net_id = new_route.net_id
                rt.type_ = new_route.type_
                rt.flags = new_route.flags
        else:
            routes.remove(rt)
            result["routes_removed"] += 1

    return result


def remove_route_if_existing(routes, remove_route):
    """
    Remove a matching route if it exists

    Returns
    -------
    dict
        Route changes (added, removed, modified)
    """
    result = dict(routes_removed=0)
    for rt in find_matching_routes(routes, remove_route):
        routes.remove(rt)
        result["routes_removed"] += 1

    return result


def combine_results(dest_results, results):
    for key in dest_results:
        if isinstance(dest_results[key], int):
            dest_results[key] += results.get(key, 0)
        elif isinstance(dest_results[key], str):
            if results.get(key):
                dest_results[key] = "\n".join((dest_results[key], results[key]))


def run_module():
    # define available arguments/parameters a user can pass to the module
    module_args = dict(
        file=dict(
            type="str",
            required=False,
            default="/usr/local/etc/TwinCAT/3.1/Target/StaticRoutes.xml",
        ),
        state=dict(type="str", required=False, default="present"),
        routes=dict(type="list", required=True),
    )

    result = dict(
        changed=False,
        routes_added=0,
        routes_removed=0,
        routes_modified=0,
        routes_before=0,
        routes_after=0,
        message="",
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True,
    )

    # if the user is working with this module in only check mode we do not
    # want to make any changes to the environment, just return the current
    # state with no modifications
    if module.check_mode:
        module.exit_json(**result)

    filename = module.params["file"]
    state = module.params["state"]
    new_routes = []

    for new_route_dict in module.params["routes"]:
        try:
            new_routes.append(Route(**new_route_dict))
        except Exception as ex:
            module.fail_json(
                msg="Invalid route specified: %s %s" % (new_route_dict, ex),
                **result,
            )

    # use whatever logic you need to determine whether or not this module
    # made any modifications to your target
    routes = load_routes_from_file(filename)
    result["routes_before"] = len(routes)
    if state == "present":
        for route in new_routes:
            combine_results(result, ensure_route_exists(routes, route))
    elif state == "absent":
        for route in new_routes:
            combine_results(result, remove_route_if_existing(routes, route))
    else:
        raise ValueError("Unknown state")

    result["routes_after"] = len(routes)
    if any(
        (
            result["routes_added"],
            result["routes_modified"],
            result["routes_removed"],
            result["routes_before"] != result["routes_after"],
        )
    ):
        result["changed"] = True
        result["message"] = "Updated and saved routes"
        save_routes_to_file(filename, routes)
    else:
        result["message"] = "No changes in routes"

    # in the event of a successful module execution, you will want to
    # simple AnsibleModule.exit_json(), passing the key/value results
    module.exit_json(**result)


def main():
    run_module()


if __name__ == "__main__":
    main()
