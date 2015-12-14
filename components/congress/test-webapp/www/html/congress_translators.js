/*
 Copyright 2015 Open Platform for NFV Project, Inc. and its contributors
  
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
  
 http://www.apache.org/licenses/LICENSE-2.0
  
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

/* This file contains the translator definition code from the Congress 
   stable/liberty branch. It's been minimally edited for javascript 
   compatibility and will be used by the Copper test webapp to:
   - present row field names to the user
   - enable test driver functions as needed, e.g. create/test policies

  The process for conversion of the python to Javascript included:
  - replace array syntax () with []
  - add semicolon line endings
  - change TRANSLATORS to an array
  - Change "True" to "true"
*/

var TRANSLATORS = [];

// Stub out this common function until it's clear how it should work
// in javascript
/*
    def safe_id(x):
        if isinstance(x, six.string_types):
            return x
        try:
            return x['id']
        except Exception:
            return str(x)
*/

    safe_id = function(x) { return(x); };

// nova: from https://raw.githubusercontent.com/openstack/congress/master/congress/datasources/nova_driver.py

    SERVERS = "servers";
    FLAVORS = "flavors";
    HOSTS = "hosts";
    FLOATING_IPS = "floating_IPs";
    SERVICES = 'services'
    AVAILABILITY_ZONES = "availability_zones";

    value_trans = {'translation-type': 'VALUE'};

    servers_translator = {
        'translation-type': 'HDICT',
        'table-name': SERVERS,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
            [{'fieldname': 'id', 'desc': 'The UUID for the server',
              'translator': value_trans},
             {'fieldname': 'name', 'desc': 'Name of the server',
              'translator': value_trans},
             {'fieldname': 'hostId', 'col': 'host_id',
              'desc': 'The UUID for the host', 'translator': value_trans},
             {'fieldname': 'status', 'desc': 'The server status',
              'translator': value_trans},
             {'fieldname': 'tenant_id', 'desc': 'The tenant ID',
              'translator': value_trans},
             {'fieldname': 'user_id',
              'desc': 'The user ID of the user who owns the server',
              'translator': value_trans},
             {'fieldname': 'image', 'col': 'image_id',
              'desc': 'Name or ID of image',
              'translator': {'translation-type': 'VALUE',
                             'extract-fn': safe_id}},
             {'fieldname': 'flavor', 'col': 'flavor_id',
              'desc': 'Name of the flavor',
              'translator': {'translation-type': 'VALUE',
                             'extract-fn': safe_id}},
             {'fieldname': 'OS-EXT-AZ:availability_zone', 'col': 'zone',
              'desc': 'The availability zone of host',
              'translator': value_trans},
             {'fieldname': 'OS-EXT-SRV-ATTR:hypervisor_hostname',
              'desc': ('The hostname of hypervisor where the server is' +
                       'running'),
              'col': 'host_name', 'translator': value_trans}]};

    flavors_translator = {
        'translation-type': 'HDICT',
        'table-name': FLAVORS,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
            [{'fieldname': 'id', 'desc': 'ID of the flavor',
              'translator': value_trans},
             {'fieldname': 'name', 'desc': 'Name of the flavor',
              'translator': value_trans},
             {'fieldname': 'vcpus', 'desc': 'Number of vcpus',
              'translator': value_trans},
             {'fieldname': 'ram', 'desc': 'Memory size in MB',
              'translator': value_trans},
             {'fieldname': 'disk', 'desc': 'Disk size in GB',
              'translator': value_trans},
             {'fieldname': 'ephemeral', 'desc': 'Ephemeral space size in GB',
              'translator': value_trans},
             {'fieldname': 'rxtx_factor', 'desc': 'RX/TX factor',
              'translator': value_trans}]};

    hosts_translator = {
        'translation-type': 'HDICT',
        'table-name': HOSTS,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
            [{'fieldname': 'host_name', 'desc': 'Name of host',
              'translator': value_trans},
             {'fieldname': 'service', 'desc': 'Enabled service',
              'translator': value_trans},
             {'fieldname': 'zone', 'desc': 'The availability zone of host',
              'translator': value_trans}]};

    floating_ips_translator = {
        'translation-type': 'HDICT',
        'table-name': FLOATING_IPS,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
            [{'fieldname': 'fixed_ip', 'desc': 'Fixed IP Address',
              'translator': value_trans},
             {'fieldname': 'id', 'desc': 'Unique ID',
              'translator': value_trans},
             {'fieldname': 'ip', 'desc': 'IP Address',
              'translator': value_trans},
             {'fieldname': 'instance_id',
              'desc': 'Name or ID of host', 'translator': value_trans},
             {'fieldname': 'pool', 'desc': 'Name of Floating IP Pool',
              'translator': value_trans}]};

    services_translator = {
        'translation-type': 'HDICT',
        'table-name': SERVICES,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
            [{'fieldname': 'id', 'col': 'service_id', 'desc': 'Service ID',
              'translator': value_trans},
             {'fieldname': 'binary', 'desc': 'Service binary',
              'translator': value_trans},
             {'fieldname': 'host', 'desc': 'Host Name',
              'translator': value_trans},
             {'fieldname': 'zone', 'desc': 'Availability Zone',
              'translator': value_trans},
             {'fieldname': 'status', 'desc': 'Status of service',
              'translator': value_trans},
             {'fieldname': 'state', 'desc': 'State of service',
              'translator': value_trans},
             {'fieldname': 'updated_at', 'desc': 'Last updated time',
              'translator': value_trans},
             {'fieldname': 'disabled_reason', 'desc': 'Disabled reason',
              'translator': value_trans}]};

    availability_zones_translator = {
        'translation-type': 'HDICT',
        'table-name': AVAILABILITY_ZONES,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
            [{'fieldname': 'zoneName', 'col': 'zone',
              'desc': 'Availability zone name', 'translator': value_trans},
             {'fieldname': 'zoneState', 'col': 'state',
              'desc': 'Availability zone state',
              'translator': value_trans}]};

    TRANSLATORS["nova"] = [servers_translator, flavors_translator, hosts_translator,
                   floating_ips_translator, services_translator,
                   availability_zones_translator];

// neutronv2: from https://raw.githubusercontent.com/openstack/congress/master/congress/datasources/neutronv2_driver.py

    NETWORKS = 'networks';
    FIXED_IPS = 'fixed_ips';
    SECURITY_GROUP_PORT_BINDINGS = 'security_group_port_bindings';
    PORTS = 'ports';
    ALLOCATION_POOLS = 'allocation_pools';
    DNS_NAMESERVERS = 'dns_nameservers';
    HOST_ROUTES = 'host_routes';
    SUBNETS = 'subnets';
    EXTERNAL_FIXED_IPS = 'external_fixed_ips';
    EXTERNAL_GATEWAY_INFOS = 'external_gateway_infos';
    ROUTERS = 'routers';
    SECURITY_GROUP_RULES = 'security_group_rules';
    SECURITY_GROUPS = 'security_groups';
    FLOATING_IPS = 'floating_ips';

    value_trans = {'translation-type': 'VALUE'};

    floating_ips_translator = {
        'translation-type': 'HDICT',
        'table-name': FLOATING_IPS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'id', 'translator': value_trans},
             {'fieldname': 'router_id', 'translator': value_trans},
             {'fieldname': 'tenant_id', 'translator': value_trans},
             {'fieldname': 'floating_network_id', 'translator': value_trans},
             {'fieldname': 'fixed_ip_address', 'translator': value_trans},
             {'fieldname': 'floating_ip_address', 'translator': value_trans},
             {'fieldname': 'port_id', 'translator': value_trans},
             {'fieldname': 'status', 'translator': value_trans}]};

    networks_translator = {
        'translation-type': 'HDICT',
        'table-name': NETWORKS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'id', 'translator': value_trans},
             {'fieldname': 'tenant_id', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans},
             {'fieldname': 'status', 'translator': value_trans},
             {'fieldname': 'admin_state_up', 'translator': value_trans},
             {'fieldname': 'shared', 'translator': value_trans}]};

    ports_fixed_ips_translator = {
        'translation-type': 'HDICT',
        'table-name': FIXED_IPS,
        'parent-key': 'id',
        'parent-col-name': 'port_id',
        'selector-type': 'DICT_SELECTOR',
        'in-list': true,
        'field-translators':
// TODO: Port ID added to complete table translation
            [{'fieldname': 'port id', 'translator': value_trans},
             {'fieldname': 'ip_address', 'translator': value_trans},
             {'fieldname': 'subnet_id', 'translator': value_trans}]};

    ports_security_groups_translator = {
//        'translation-type': 'LIST',
        'translation-type': 'HDICT',
        'table-name': SECURITY_GROUP_PORT_BINDINGS,
        'parent-key': 'id',
        'parent-col-name': 'port_id',
        'val-col': 'security_group_id',
//        'translator': value_trans};
// TODO: Port ID added to complete table translation
        'field-translators':
            [{'fieldname': 'port id', 'translator': value_trans},
             {'fieldname': 'security_group_id', 'translator': value_trans}]};

    ports_translator = {
        'translation-type': 'HDICT',
        'table-name': PORTS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'id', 'translator': value_trans},
             {'fieldname': 'tenant_id', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans},
             {'fieldname': 'network_id', 'translator': value_trans},
             {'fieldname': 'mac_address', 'translator': value_trans},
             {'fieldname': 'admin_state_up', 'translator': value_trans},
             {'fieldname': 'status', 'translator': value_trans},
             {'fieldname': 'device_id', 'translator': value_trans},
             {'fieldname': 'device_owner', 'translator': value_trans},
             {'fieldname': 'fixed_ips',
              'translator': ports_fixed_ips_translator},
             {'fieldname': 'security_groups',
              'translator': ports_security_groups_translator}]};

    subnets_allocation_pools_translator = {
        'translation-type': 'HDICT',
        'table-name': ALLOCATION_POOLS,
        'parent-key': 'id',
        'selector-type': 'DICT_SELECTOR',
        'in-list': true,
        'field-translators':
// TODO: ID was missing from the field list
            [{'fieldname': 'id', 'translator': value_trans},
             {'fieldname': 'start', 'translator': value_trans},
             {'fieldname': 'end', 'translator': value_trans}]};

    subnets_dns_nameservers_translator = {
        'translation-type': 'LIST',
        'table-name': DNS_NAMESERVERS,
        'parent-key': 'id',
        'parent-col-name': 'subnet_id',
        'val-col': 'dns_nameserver',
        'translator': value_trans};

    subnets_routes_translator = {
        'translation-type': 'HDICT',
        'table-name': HOST_ROUTES,
        'parent-key': 'id',
        'parent-col-name': 'subnet_id',
        'selector-type': 'DICT_SELECTOR',
        'in-list': true,
        'field-translators':
            [{'fieldname': 'destination', 'translator': value_trans},
             {'fieldname': 'nexthop', 'translator': value_trans}]};

    subnets_translator = {
        'translation-type': 'HDICT',
        'table-name': SUBNETS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'id', 'translator': value_trans},
             {'fieldname': 'tenant_id', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans},
             {'fieldname': 'network_id', 'translator': value_trans},
             {'fieldname': 'ip_version', 'translator': value_trans},
             {'fieldname': 'cidr', 'translator': value_trans},
             {'fieldname': 'gateway_ip', 'translator': value_trans},
             {'fieldname': 'enable_dhcp', 'translator': value_trans},
             {'fieldname': 'ipv6_ra_mode', 'translator': value_trans},
             {'fieldname': 'ipv6_address_mode', 'translator': value_trans},
             {'fieldname': 'allocation_pools',
              'translator': subnets_allocation_pools_translator},
             {'fieldname': 'dns_nameservers',
              'translator': subnets_dns_nameservers_translator},
             {'fieldname': 'host_routes',
              'translator': subnets_routes_translator}]};

    external_fixed_ips_translator = {
        'translation-type': 'HDICT',
        'table-name': EXTERNAL_FIXED_IPS,
        'parent-key': 'router_id',
        'parent-col-name': 'router_id',
        'selector-type': 'DICT_SELECTOR',
        'in-list': true,
        'field-translators':
            [{'fieldname': 'subnet_id', 'translator': value_trans},
             {'fieldname': 'ip_address', 'translator': value_trans}]};

    routers_external_gateway_infos_translator = {
        'translation-type': 'HDICT',
        'table-name': EXTERNAL_GATEWAY_INFOS,
        'parent-key': 'id',
        'parent-col-name': 'router_id',
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'network_id', 'translator': value_trans},
             {'fieldname': 'enable_snat', 'translator': value_trans},
             {'fieldname': 'external_fixed_ips',
              'translator': external_fixed_ips_translator}]};

    routers_translator = {
        'translation-type': 'HDICT',
        'table-name': ROUTERS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'id', 'translator': value_trans},
             {'fieldname': 'tenant_id', 'translator': value_trans},
             {'fieldname': 'status', 'translator': value_trans},
             {'fieldname': 'admin_state_up', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans},
             {'fieldname': 'distributed', 'translator': value_trans},
             {'fieldname': 'external_gateway_info',
              'translator': routers_external_gateway_infos_translator}]};

    security_group_rules_translator = {
        'translation-type': 'HDICT',
        'table-name': SECURITY_GROUP_RULES,
        'parent-key': 'id',
        'parent-col-name': 'security_group_id',
        'selector-type': 'DICT_SELECTOR',
        'in-list': true,
        'field-translators':
// TODO: Port ID added to complete table translation
            [{'fieldname': 'port id', 'translator': value_trans},
             {'fieldname': 'id', 'translator': value_trans},
             {'fieldname': 'tenant_id', 'translator': value_trans},
             {'fieldname': 'remote_group_id', 'translator': value_trans},
             {'fieldname': 'direction', 'translator': value_trans},
             {'fieldname': 'ethertype', 'translator': value_trans},
             {'fieldname': 'protocol', 'translator': value_trans},
             {'fieldname': 'port_range_min', 'translator': value_trans},
             {'fieldname': 'port_range_max', 'translator': value_trans},
             {'fieldname': 'remote_ip_prefix', 'translator': value_trans}]};

    security_group_translator = {
        'translation-type': 'HDICT',
        'table-name': SECURITY_GROUPS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'id', 'translator': value_trans},
             {'fieldname': 'tenant_id', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans},
             {'fieldname': 'description', 'translator': value_trans},
             {'fieldname': 'security_group_rules',
              'translator': security_group_rules_translator}]};

// TODO: Some translators were missing from the list
    TRANSLATORS["neutronv2"] = [floating_ips_translator, networks_translator, ports_fixed_ips_translator, ports_security_groups_translator, ports_translator, subnets_allocation_pools_translator, subnets_dns_nameservers_translator, subnets_routes_translator, subnets_translator, external_fixed_ips_translator, routers_external_gateway_infos_translator, routers_translator, security_group_rules_translator, security_group_translator];

// keystone: from https://raw.githubusercontent.com/openstack/congress/master/congress/datasources/keystone_driver.py

    USERS = "users";
    ROLES = "roles";
    TENANTS = "tenants";

    value_trans = {'translation-type': 'VALUE'};

    users_translator = {
        'translation-type': 'HDICT',
        'table-name': USERS,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
            [{'fieldname': 'username', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans},
             {'fieldname': 'enabled', 'translator': value_trans},
             {'fieldname': 'tenantId', 'translator': value_trans},
             {'fieldname': 'id', 'translator': value_trans},
             {'fieldname': 'email', 'translator': value_trans}]};

    roles_translator = {
        'translation-type': 'HDICT',
        'table-name': ROLES,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
            [{'fieldname': 'id', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans}]};

    tenants_translator = {
        'translation-type': 'HDICT',
        'table-name': TENANTS,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
            [{'fieldname': 'enabled', 'translator': value_trans},
             {'fieldname': 'description', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans},
             {'fieldname': 'id', 'translator': value_trans}]};

    TRANSLATORS["keystone"] = [users_translator, roles_translator, tenants_translator];

// heat: from https://raw.githubusercontent.com/openstack/congress/master/congress/datasources/heatv1_driver.py

    STACKS = "stacks";
    STACKS_LINKS = "stacks_links";
    DEPLOYMENTS = "deployments";    STACKS = "stacks";
    STACKS_LINKS = "stacks_links";
    DEPLOYMENTS = "deployments";
    DEPLOYMENT_OUTPUT_VALUES = "deployment_output_values";

// TODO(thinrichs): add resources, events, snapshots

    value_trans = {'translation-type': 'VALUE'};
    stacks_links_translator = {
        'translation-type': 'HDICT',
        'table-name': STACKS_LINKS,
        'parent-key': 'id',
        'selector-type': 'DICT_SELECTOR',
        'in-list': true,
        'field-translators':
            [{'fieldname': 'href', 'translator': value_trans},
             {'fieldname': 'rel', 'translator': value_trans}]};

    stacks_translator = {
        'translation-type': 'HDICT',
        'table-name': STACKS,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
        [{'fieldname': 'id', 'translator': value_trans},
         {'fieldname': 'stack_name', 'translator': value_trans},
         {'fieldname': 'description', 'translator': value_trans},
         {'fieldname': 'creation_time', 'translator': value_trans},
         {'fieldname': 'updated_time', 'translator': value_trans},
         {'fieldname': 'stack_status', 'translator': value_trans},
         {'fieldname': 'stack_status_reason', 'translator': value_trans},
         {'fieldname': 'stack_owner', 'translator': value_trans},
         {'fieldname': 'parent', 'translator': value_trans},
         {'fieldname': 'links', 'translator': stacks_links_translator}]};

    deployments_output_values_translator = {
        'translation-type': 'HDICT',
        'table-name': DEPLOYMENT_OUTPUT_VALUES,
        'parent-key': 'id',
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'deploy_stdout', 'translator': value_trans},
             {'fieldname': 'deploy_stderr', 'translator': value_trans},
             {'fieldname': 'deploy_status_code', 'translator': value_trans},
             {'fieldname': 'result', 'translator': value_trans}]};

    software_deployment_translator = {
        'translation-type': 'HDICT',
        'table-name': DEPLOYMENTS,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
        [{'fieldname': 'status', 'translator': value_trans},
         {'fieldname': 'server_id', 'translator': value_trans},
         {'fieldname': 'config_id', 'translator': value_trans},
         {'fieldname': 'action', 'translator': value_trans},
         {'fieldname': 'status_reason', 'translator': value_trans},
         {'fieldname': 'id', 'translator': value_trans},
         {'fieldname': 'output_values',
          'translator': deployments_output_values_translator}]};

    TRANSLATORS["heat"] = [stacks_translator, software_deployment_translator];
    DEPLOYMENT_OUTPUT_VALUES = "deployment_output_values";

/* TODO(thinrichs): add resources, events, snapshots
*/
    value_trans = {'translation-type': 'VALUE'};
    stacks_links_translator = {
        'translation-type': 'HDICT',
        'table-name': STACKS_LINKS,
        'parent-key': 'id',
        'selector-type': 'DICT_SELECTOR',
        'in-list': true,
        'field-translators':
            [{'fieldname': 'href', 'translator': value_trans},
             {'fieldname': 'rel', 'translator': value_trans}]};

    stacks_translator = {
        'translation-type': 'HDICT',
        'table-name': STACKS,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
        [{'fieldname': 'id', 'translator': value_trans},
         {'fieldname': 'stack_name', 'translator': value_trans},
         {'fieldname': 'description', 'translator': value_trans},
         {'fieldname': 'creation_time', 'translator': value_trans},
         {'fieldname': 'updated_time', 'translator': value_trans},
         {'fieldname': 'stack_status', 'translator': value_trans},
         {'fieldname': 'stack_status_reason', 'translator': value_trans},
         {'fieldname': 'stack_owner', 'translator': value_trans},
         {'fieldname': 'parent', 'translator': value_trans},
         {'fieldname': 'links', 'translator': stacks_links_translator}]};

    deployments_output_values_translator = {
        'translation-type': 'HDICT',
        'table-name': DEPLOYMENT_OUTPUT_VALUES,
        'parent-key': 'id',
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'deploy_stdout', 'translator': value_trans},
             {'fieldname': 'deploy_stderr', 'translator': value_trans},
             {'fieldname': 'deploy_status_code', 'translator': value_trans},
             {'fieldname': 'result', 'translator': value_trans}]};

    software_deployment_translator = {
        'translation-type': 'HDICT',
        'table-name': DEPLOYMENTS,
        'selector-type': 'DOT_SELECTOR',
        'field-translators':
        [{'fieldname': 'status', 'translator': value_trans},
         {'fieldname': 'server_id', 'translator': value_trans},
         {'fieldname': 'config_id', 'translator': value_trans},
         {'fieldname': 'action', 'translator': value_trans},
         {'fieldname': 'status_reason', 'translator': value_trans},
         {'fieldname': 'id', 'translator': value_trans},
         {'fieldname': 'output_values',
          'translator': deployments_output_values_translator}]};

    TRANSLATORS["heat"] = [stacks_translator, software_deployment_translator];

// glancev2: from https://raw.githubusercontent.com/openstack/congress/master/congress/datasources/glancev2_driver.py

    IMAGES = "images";
    TAGS = "tags";

    value_trans = {'translation-type': 'VALUE'};
    images_translator = {
        'translation-type': 'HDICT',
        'table-name': IMAGES,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'id', 'translator': value_trans},
             {'fieldname': 'status', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans},
             {'fieldname': 'container_format', 'translator': value_trans},
             {'fieldname': 'created_at', 'translator': value_trans},
             {'fieldname': 'updated_at', 'translator': value_trans},
             {'fieldname': 'disk_format', 'translator': value_trans},
             {'fieldname': 'owner', 'translator': value_trans},
             {'fieldname': 'protected', 'translator': value_trans},
             {'fieldname': 'min_ram', 'translator': value_trans},
             {'fieldname': 'min_disk', 'translator': value_trans},
             {'fieldname': 'checksum', 'translator': value_trans},
             {'fieldname': 'size', 'translator': value_trans},
             {'fieldname': 'file', 'translator': value_trans},
             {'fieldname': 'kernel_id', 'translator': value_trans},
             {'fieldname': 'ramdisk_id', 'translator': value_trans},
             {'fieldname': 'schema', 'translator': value_trans},
             {'fieldname': 'visibility', 'translator': value_trans},
             {'fieldname': 'tags',
              'translator': {'translation-type': 'LIST',
                             'table-name': TAGS,
                             'val-col': 'tag',
                             'parent-key': 'id',
                             'parent-col-name': 'image_id',
                             'translator': value_trans}}]};

    TRANSLATORS["glancev2"] = [images_translator];

// ceilometer: from https://raw.githubusercontent.com/openstack/congress/master/congress/datasources/ceilometer_driver.py

    METERS = "meters";
    ALARMS = "alarms";
    EVENTS = "events";
    EVENT_TRAITS = "events.traits";
    ALARM_THRESHOLD_RULE = "alarms.threshold_rule";
    STATISTICS = "statistics";

    value_trans = {'translation-type': 'VALUE'};

    meters_translator = {
        'translation-type': 'HDICT',
        'table-name': METERS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'meter_id', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans},
             {'fieldname': 'type', 'translator': value_trans},
             {'fieldname': 'unit', 'translator': value_trans},
             {'fieldname': 'source', 'translator': value_trans},
             {'fieldname': 'resource_id', 'translator': value_trans},
             {'fieldname': 'user_id', 'translator': value_trans},
             {'fieldname': 'project_id', 'translator': value_trans}]};

    alarms_translator = {
        'translation-type': 'HDICT',
        'table-name': ALARMS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'alarm_id', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans},
             {'fieldname': 'state', 'translator': value_trans},
             {'fieldname': 'enabled', 'translator': value_trans},
             {'fieldname': 'threshold_rule', 'col': 'threshold_rule_id',
              'translator': {'translation-type': 'VDICT',
                             'table-name': ALARM_THRESHOLD_RULE,
                             'id-col': 'threshold_rule_id',
                             'key-col': 'key', 'val-col': 'value',
                             'translator': value_trans}},
             {'fieldname': 'type', 'translator': value_trans},
             {'fieldname': 'description', 'translator': value_trans},
             {'fieldname': 'time_constraints', 'translator': value_trans},
             {'fieldname': 'user_id', 'translator': value_trans},
             {'fieldname': 'project_id', 'translator': value_trans},
             {'fieldname': 'alarm_actions', 'translator': value_trans},
             {'fieldname': 'ok_actions', 'translator': value_trans},
             {'fieldname': 'insufficient_data_actions', 'translator':
             value_trans},
             {'fieldname': 'repeat_actions', 'translator': value_trans},
             {'fieldname': 'timestamp', 'translator': value_trans},
             {'fieldname': 'state_timestamp', 'translator': value_trans},
             ]};

    events_translator = {
        'translation-type': 'HDICT',
        'table-name': EVENTS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'message_id', 'translator': value_trans},
             {'fieldname': 'event_type', 'translator': value_trans},
             {'fieldname': 'generated', 'translator': value_trans},
             {'fieldname': 'traits',
              'translator': {'translation-type': 'HDICT',
                             'table-name': EVENT_TRAITS,
                             'selector-type': 'DICT_SELECTOR',
                             'in-list': true,
                             'parent-key': 'message_id',
                             'parent-col-name': 'event_message_id',
                             'field-translators':
                                 [{'fieldname': 'name',
                                   'translator': value_trans},
                                  {'fieldname': 'type',
                                   'translator': value_trans},
                                  {'fieldname': 'value',
                                   'translator': value_trans}
                                  ]}}
             ]};

    statistics_translator = {
        'translation-type': 'HDICT',
        'table-name': STATISTICS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'meter_name', 'translator': value_trans},
             {'fieldname': 'groupby', 'col': 'resource_id',
              'translator': {'translation-type': 'VALUE',
                             'extract-fn': safe_id}},
             {'fieldname': 'avg', 'translator': value_trans},
             {'fieldname': 'count', 'translator': value_trans},
             {'fieldname': 'duration', 'translator': value_trans},
             {'fieldname': 'duration_start', 'translator': value_trans},
             {'fieldname': 'duration_end', 'translator': value_trans},
             {'fieldname': 'max', 'translator': value_trans},
             {'fieldname': 'min', 'translator': value_trans},
             {'fieldname': 'period', 'translator': value_trans},
             {'fieldname': 'period_end', 'translator': value_trans},
             {'fieldname': 'period_start', 'translator': value_trans},
             {'fieldname': 'sum', 'translator': value_trans},
             {'fieldname': 'unit', 'translator': value_trans}]};

    TRANSLATORS["ceilometer"] = [meters_translator, alarms_translator, events_translator,
                   statistics_translator];

// swift: from https://raw.githubusercontent.com/openstack/congress/master/congress/datasources/swift_driver.py

    CONTAINERS = "containers";
    OBJECTS = "objects";

    value_trans = {'translation-type': 'VALUE'};

    containers_translator = {
        'translation-type': 'HDICT',
        'table-name': CONTAINERS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'count', 'translator': value_trans},
             {'fieldname': 'bytes', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans}]};

    objects_translator = {
        'translation-type': 'HDICT',
        'table-name': OBJECTS,
        'selector-type': 'DICT_SELECTOR',
        'field-translators':
            [{'fieldname': 'bytes', 'translator': value_trans},
             {'fieldname': 'last_modified', 'translator': value_trans},
             {'fieldname': 'hash', 'translator': value_trans},
             {'fieldname': 'name', 'translator': value_trans},
             {'fieldname': 'content_type', 'translator': value_trans},
             {'fieldname': 'container_name', 'translator': value_trans}]};

    TRANSLATORS["swift"] = [containers_translator, objects_translator];
