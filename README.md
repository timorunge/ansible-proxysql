proxysql
========

This role installs and configures [ProxySQL](https://proxysql.com/) - the
high performance, high availability, protocol aware proxy for MySQL.

Since version 2.3.0 Ansible is providing an
[module to configure ProxySQL](https://docs.ansible.com/ansible/latest/modules/list_of_database_modules.html#proxysql)
itself. This Ansible role is using this functionality but adding some
(hopefully useful) features on top:

* Automatic installation for [different operating systems](#testing)
* (Pre-) generation of [proxysql.cnf](templates/proxysql.cnf.j2)
* Manage a
  [ProxySQL-Cluster](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster)
  (with a
  [custom module](https://github.com/timorunge/ansible-proxysql_proxysql_servers)
  which adds the functionality to configure ProxySQL servers)
* Differentiate between dynamic and static `global_variables` - restart
  ProxySQL if required

Please also take a look at the
"[Known issues or: Good to know](#known-issues-or-good-to-know)" section in
this document.

Requirements
------------

This role requires
[Ansible 2.5.0](https://docs.ansible.com/ansible/devel/roadmap/ROADMAP_2_5.html)
or higher.

You can simply use pip to install (and define) a stable version:

```sh
pip install ansible==2.7.0
```

All platform requirements are listed in the metadata file.

Install
-------

```sh
ansible-galaxy install timorunge.proxysql
```

Role Variables
--------------

The variables that can be passed to this role. For all variables, take
a look at [defaults/main.yml](defaults/main.yml).

```yaml
# Enable / disable ProxySQL as a service.
# Type: Bool
proxysql_service_enabled: True

# Restart ProxySQL if static variables are changing. For a list of static
# variables take a look at `proxysql_non_dynamic_variables` in `vars/main.yml`.
# Type: Bool
proxysql_restart_on_static_variables_change: True

# Repository

# Use the official ProxySQL repository. If set to `False` the module will
# automatically download the defined version as a package.
# Type: Bool
proxysql_use_official_repo: True

# The ProxySQL version which should be installed if not using the ProxySQL
# repository.
# Type: Int
proxysql_version: 1.4.11

# Configuration

# The path where ProxySQL should save it's database and logs.
# Type: Str
proxysql_datadir: /var/lib/proxysql

# Define the proxysql.cnf template
# Type: Str
proxysql_proxysql_cnf_template: proxysql.cnf.j2

# The login variables for the configuration of ProxySQL itself. They are just
# used inside the `main.yml` file and here to simplify the configuration.
# Type: Str
proxysql_login_admin_host: 127.0.0.1
proxysql_login_admin_password: admin
proxysql_login_admin_port: 6032
proxysql_login_admin_user: admin

# Global variables
# `admin_variables` in `proxysql_global_variables_kv`: contains global
# variables that control the functionality of the admin interface.
# `admin_variables` are prefixed with `admin-`.
# `mysql_variables`: in `proxysql_global_variables_kv` contains global
# variables that control the functionality for handling the incoming
# MySQL traffic.
# `mysql_variables` are prefixed with `mysql-`.

# The variables should be either a string or an integer. You should mark
# a boolean value as a string, e.g. "True" or "False".

# For a full reference take a look at:
# https://github.com/sysown/proxysql/wiki/Global-variables

# Format:
# Type: Dict
# proxysql_global_variables:
#   load_to_runtime: "True"
#   save_to_disk: "True"
#   login_host: "{{ proxysql_login_admin_host }}"
#   login_password: "{{ proxysql_login_admin_password }}"
#   login_port: "{{ proxysql_login_admin_port }}"
#   login_user: "{{ proxysql_login_admin_user }}"
proxysql_global_variables:
  login_host: "{{ proxysql_login_admin_host }}"
  login_password: "{{ proxysql_login_admin_password }}"
  login_port: "{{ proxysql_login_admin_port }}"
  login_user: "{{ proxysql_login_admin_user }}"
# Format:
# Type: Dict
# proxysql_global_variables_kv:
#   key: value
# e.g.:
# proxysql_global_variables_kv:
#   admin-admin_credentials: "{{ proxysql_login_admin_user }}:{{ proxysql_login_admin_password }}"
#   admin-mysql_ifaces: "{{ proxysql_login_admin_host }}:{{ proxysql_login_admin_port }}"
#   mysql-interfaces: 0.0.0.0:6033
#   mysql-commands_stats: "True"
#   mysql-threads: 4
proxysql_global_variables_kv: {}

# Backend servers
# `proxysql_backend_servers`: contains rows for the mysql_servers table from
# the admin interface. Basically, these define the backend servers towards
# which the incoming MySQL traffic is routed.

# For a full reference take a look at:
# https://docs.ansible.com/ansible/latest/modules/proxysql_backend_servers_module.html
# Important: This module uses `hostgroup` (which is the correct name in the
# database) instead of `hostgroup_id` (which is the default in the Ansible
# module)!

# Format:
# Type: Dict
# proxysql_backend_servers:
#   mysql-srv1-hg1:
#     comment: mysql-srv1-hg1
#     hostgroup: 1
#     hostname: 172.16.77.101
#     login_host: "{{ proxysql_login_admin_host }}"
#     login_password: "{{ proxysql_login_admin_password }}"
#     login_port: "{{ proxysql_login_admin_port }}"
#     login_user: "{{ proxysql_login_admin_user }}"
#     max_connections: 1000
#     max_replication_lag: 0
#     status: ONLINE
#     weight: 1
#   mysql-srv1-hg2:
#     comment: mysql-srv1-hg2
#     hostgroup: 2
#     hostname: 172.16.77.101
#     login_host: "{{ proxysql_login_admin_host }}"
#     login_password: "{{ proxysql_login_admin_password }}"
#     login_port: "{{ proxysql_login_admin_port }}"
#     login_user: "{{ proxysql_login_admin_user }}"
#     max_connections: 1000
#     max_replication_lag: 0
#     status: ONLINE
#     weight: 1
proxysql_backend_servers: {}

# ProxySQL servers
# `proxysql_proxysql_servers`: contains rows for the proxysql_servers table
# from the admin interface. Basically, these define the ProxySQL servers
# which are used for clustering.

# For a full reference take a look at:
# `library/proxysql_proxysql_servers.py` since this is not a part of the
# official Ansible package.

# Format:
# Type: Dict
# proxysql_proxysql_servers:
#   proxysql-srv-1:
#     comment: proxysql-srv-1
#     hostname: 172.16.77.201
#     login_host: "{{ proxysql_login_admin_host }}"
#     login_password: "{{ proxysql_login_admin_password }}"
#     login_port: "{{ proxysql_login_admin_port }}"
#     login_user: "{{ proxysql_login_admin_user }}"
#     weight: 0
#   proxysql-srv-2:
#     comment: proxysql-srv-2
#     hostname: 172.16.77.202
#     login_host: "{{ proxysql_login_admin_host }}"
#     login_password: "{{ proxysql_login_admin_password }}"
#     login_port: "{{ proxysql_login_admin_port }}"
#     login_user: "{{ proxysql_login_admin_user }}"
#     weight: 0
proxysql_proxysql_servers: {}

# Replication hostgroups
# `proxysql_replication_hostgroups`: represent a pair of writer_hostgroup
# and reader_hostgroup. ProxySQL will monitor the value of read_only for all
# the servers in specified hostgroups, and based on the value of read_only
# will assign the server to the writer or reader hostgroups.

# For a full reference take a look at:
# https://docs.ansible.com/ansible/latest/modules/proxysql_replication_hostgroups_module.html

# Format:
# Type: Dict
# proxysql_replication_hostgroups:
#   Cluster:
#     comment: Cluster
#     login_host: "{{ proxysql_login_admin_host }}"
#     login_password: "{{ proxysql_login_admin_password }}"
#     login_port: "{{ proxysql_login_admin_port }}"
#     login_user: "{{ proxysql_login_admin_user }}"
#     reader_hostgroup: 2
#     writer_hostgroup: 1
proxysql_replication_hostgroups: {}

# Users
# `proxysql_mysql_users`: contains rows for the mysql_users table from the
# admin interface. Basically, these define the users which can connect to the
# proxy, and the users with which the proxy can connect to the backend servers.

# For a full reference take a look at:
# http://docs.ansible.com/ansible/latest/proxysql_mysql_users_module.html

# Format:
# Type: Dict
# proxysql_mysql_users:
#   user1:
#     active: 1
#     backend: 1
#     default_hostgroup: 1
#     fast_forward: 0
#     frontend: 1
#     login_host: "{{ proxysql_login_admin_host }}"
#     login_password: "{{ proxysql_login_admin_password }}"
#     login_port: "{{ proxysql_login_admin_port }}"
#     login_user: "{{ proxysql_login_admin_user }}"
#     max_connections: 10000
#     password: Passw0rd
#     transaction_persistent: 1
#     username: user1
#   user2:
#     active: 1
#     backend: 1
#     default_hostgroup: 2
#     fast_forward: 0
#     frontend: 1
#     login_host: "{{ proxysql_login_admin_host }}"
#     login_password: "{{ proxysql_login_admin_password }}"
#     login_port: "{{ proxysql_login_admin_port }}"
#     login_user: "{{ proxysql_login_admin_user }}"
#     max_connections: 1000
#     password: dr0wssaP
#     transaction_persistent: 1
#     username: user2
proxysql_mysql_users: {}

# Query rules
# `proxysql_query_rules` contains rows for the mysql_query_rules table from
# the admin interface. Basically, these define the rules used to classify and
# route the incoming MySQL traffic, according to various criteria (patterns
# matched, user used to run the query, etc.).

# For a full reference take a look at:
# http://docs.ansible.com/ansible/latest/proxysql_query_rules_module.html

# Format:
# Type: Dict
# proxysql_query_rules:
#   catchall:
#     active: 1
#     apply: 1
#     destination_hostgroup: 1
#     flagIN: 0
#     login_host: "{{ proxysql_login_admin_host }}"
#     login_password: "{{ proxysql_login_admin_password }}"
#     login_port: "{{ proxysql_login_admin_port }}"
#     login_user: "{{ proxysql_login_admin_user }}"
#     match_pattern: .*@.*
#     negate_match_pattern: 0
#     rule_id: 1
#   selectforupdate:
#     active: 1
#     apply: 1
#     destination_hostgroup: 1
#     flagIN: 0
#     login_host: "{{ proxysql_login_admin_host }}"
#     login_password: "{{ proxysql_login_admin_password }}"
#     login_port: "{{ proxysql_login_admin_port }}"
#     login_user: "{{ proxysql_login_admin_user }}"
#     match_pattern: ^SELECT.*FOR UPDATE
#     negate_match_pattern: 0
#     rule_id: 2
#   select:
#     active: 1
#     apply: 0
#     destination_hostgroup: 2
#     flagIN: 0
#     login_host: "{{ proxysql_login_admin_host }}"
#     login_password: "{{ proxysql_login_admin_password }}"
#     login_port: "{{ proxysql_login_admin_port }}"
#     login_user: "{{ proxysql_login_admin_user }}"
#     match_pattern: ^SELECT.*
#     negate_match_pattern: 0
#     rule_id: 3
proxysql_query_rules: {}
```

Examples
--------

### 1) Full configuration example

Here you can see a full example of a configuration of ProxySQL. In this case
the role will download the `1.4.11` package directly and not use the repository
(`proxysql_use_official_repo` is set to `False`).

This is basically (with some small changes) the [test.yml](tests/test.yml)
file which is used for testing.

```yaml
- hosts: proxysql
  gather_facts: True
  vars:
    proxysql_version: 1.4.11
    proxysql_service_enabled: True
    proxysql_use_official_repo: True
    proxysql_login_admin_host: 127.0.0.1
    proxysql_login_admin_password: admin
    proxysql_login_admin_port: 6032
    proxysql_login_admin_user: admin
    proxysql_global_variables:
      login_host: "{{ proxysql_login_admin_host }}"
      login_password: "{{ proxysql_login_admin_password }}"
      login_port: "{{ proxysql_login_admin_port }}"
      login_user: "{{ proxysql_login_admin_user }}"
    proxysql_global_variables_kv:
      admin-admin_credentials: "{{ proxysql_login_admin_user }}:{{ proxysql_login_admin_password }}"
      admin-mysql_ifaces: "{{ proxysql_login_admin_host }}:{{ proxysql_login_admin_port }}"
      mysql-commands_stats: "True"
      mysql-connect_retries_on_failure: 10
      mysql-connect_timeout_server: 3000
      mysql-default_charset: utf8
      mysql-default_query_delay: 0
      mysql-default_query_timeout: 300000
      mysql-default_schema: information_schema
      mysql-default_sql_mode: >
                              STRICT_TRANS_TABLES,
                              ERROR_FOR_DIVISION_BY_ZERO,
                              NO_AUTO_CREATE_USER,
                              NO_ENGINE_SUBSTITUTION
      mysql-interfaces: 127.0.0.1:6033
      mysql-max_connections: 8192
      mysql-monitor_read_only_interval: 1500
      mysql-monitor_read_only_timeout: 500
      mysql-ping_timeout_server: 500
      mysql-poll_timeout: 2000
      mysql-query_retries_on_failure: 1
      mysql-sessions_sort: "True"
      mysql-threads: 4
    proxysql_backend_servers:
      mysql-srv1-hg1:
        comment: mysql-srv1-hg1
        hostgroup: 1
        hostname: 172.16.77.101
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        max_connections: 1000
        max_replication_lag: 0
        status: ONLINE
        weight: 1
      mysql-srv1-hg2:
        comment: mysql-srv1-hg2
        hostgroup: 2
        hostname: 172.16.77.101
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        max_connections: 1000
        max_replication_lag: 0
        status: ONLINE
        weight: 1
      mysql-srv2-hg2:
        comment: mysql-srv2-hg2
        hostgroup: 2
        hostname: 172.16.77.102
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        max_connections: 2000
        max_replication_lag: 5
        status: ONLINE
        weight: 1
      mysql-srv3-hg2:
        comment: mysql-srv3-hg2
        hostgroup: 2
        hostname: 172.16.77.103
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        max_connections: 2000
        max_replication_lag: 5
        status: OFFLINE_HARD
        weight: 1
    proxysql_proxysql_servers:
      proxysql-srv-1:
        comment: proxysql-srv-1
        hostname: 172.16.77.201
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        port: 6032
        weight: 0
      proxysql-srv-2:
        comment: proxysql-srv-2
        hostname: 172.16.77.202
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        port: 6032
        weight: 0
    proxysql_replication_hostgroups:
      Cluster:
        comment: Cluster
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        reader_hostgroup: 2
        writer_hostgroup: 1
    proxysql_mysql_users:
      user1:
        active: 1
        backend: 1
        default_hostgroup: 1
        fast_forward: 0
        frontend: 1
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        max_connections: 10000
        password: Passw0rd
        transaction_persistent: 1
        username: user1
      user2:
        active: 1
        backend: 1
        default_hostgroup: 1
        fast_forward: 0
        frontend: 1
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        max_connections: 1000
        password: dr0wssaP
        transaction_persistent: 1
        username: user2
    proxysql_query_rules:
      catchall:
        active: 1
        apply: 1
        destination_hostgroup: 1
        flagIN: 0
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        match_pattern: .*@.*
        negate_match_pattern: 0
        rule_id: 1
      selectforupdate:
        active: 1
        apply: 1
        destination_hostgroup: 1
        flagIN: 0
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        match_pattern: ^SELECT.*FOR UPDATE
        negate_match_pattern: 0
        rule_id: 2
      select:
        active: 1
        apply: 0
        destination_hostgroup: 2
        flagIN: 0
        login_host: "{{ proxysql_login_admin_host }}"
        login_password: "{{ proxysql_login_admin_password }}"
        login_port: "{{ proxysql_login_admin_port }}"
        login_user: "{{ proxysql_login_admin_user }}"
        match_pattern: ^SELECT.*
        negate_match_pattern: 0
        rule_id: 3
  roles:
    - timorunge.proxysql
```

### 2) Installation from the official repository

Use the ProxySQL repository (`proxysql_use_official_repo` is set to `True`).
ProxySQL itself is not providing packages in the repository for Ubuntu > 16.04.

Just set the `proxysql_use_official_repo` to `False` for newer Ubuntu releases.

```yaml
- hosts: proxysql
  vars:
    proxysql_use_official_repo: True
    proxysql_login_admin_host: 127.0.0.1
    proxysql_login_admin_password: admin
    proxysql_login_admin_port: 6032
    proxysql_login_admin_user: admin
    ...
```

### 3) Don't restart ProxySQL after static variable change

If you'd like to restart ProxySQL on your own after a config change of static
variables you have to set `proxysql_restart_on_static_variables_change` to
`False`.

In this case you're hitting an [known issue](#known-issues-or-good-to-know)
which is no drama. In this case idempotence tests will fail.

You don't have to apply Ansible again after a manual restart.

```yaml
- hosts: proxysql
  vars:
    proxysql_use_official_repo: False
    proxysql_restart_on_static_variables_change: False
    proxysql_login_admin_host: 127.0.0.1
    proxysql_login_admin_password: admin
    proxysql_login_admin_port: 6032
    proxysql_login_admin_user: admin
    ...
```

Known issues or: Good to know
-----------------------------

### 1) ProxySQL > 1.4.7 on Ubuntu 16.04 (fixed)

On Ubuntu 16.04 Ansible (version does not matter) / ProxySQL > 1.4.7 seems
to have problems to communicate correctly via `mysql-python` /
`python-mysqldb`.

Example error:

```sh
"unable to modify server.. (1045, 'unrecognized token: \"\\'\\n  AND compression = 0\\n  AND weight = 1\\n  AND use_ssl = 0\\n  AND max_connections = 2000\\n  AND max_latency_ms = 0\\n  AND max_replication_lag = 5\"')"
```

**Note:**

I've done the following little research with `mysql-python` installed via `pip`
on Ubuntu 16.04. Don't worry, it's also failing with `python-mysqldb`.

---

In the MySQLdb python library the `execute` method (class `BaseCursor`) is
generating a query in the following way:

```python
query = query % tuple([db.literal(item) for item in args])
```

`db.literal` is part of the `Connection` class and returns single objects as a
string and mutliple objects as a sequence while it's converting each sequence
as well.

```python
def literal(self, o):
  # ...
  return self.escape(o, self.encoders)
```

[`self.escape`](https://github.com/farcepest/MySQLdb1/blob/master/_mysql.c#L1226)
should escape all special characters in the given object and is using a mapping
dict to provide quoting functions for each type. This is `self.encoders` which
- per default and not set different - using `MySQLdb.converters`.

The mapping for a string is `StringType: Thing2Literal`. So the string will be
escaped with the method `Thing2Literal`.

```python
def Thing2Literal(o, d):
  # ...
  return string_literal(o, d)
```

[`string_literal`](https://github.com/farcepest/MySQLdb1/blob/master/_mysql.c#L1139)
should convert our string object into a SQL string literal. This means, any
special SQL characters are escaped, and it is enclosed within single quotes.
In other words, it performs:

```python
"'%s'" % escape_string(str(obj))
```

During escaping the string the string objects are getting deleted and are
returning just a single quote (`'`).

Since in the tests nothing beside the version of ProxySQL changed I assume
that a change in ProxySQL
([diff 1.4.7 vs. 1.4.8](https://github.com/sysown/proxysql/compare/1.4.7...1.4.8))
is causing Ansible to fail. Because ProxySQL itself - if not triggered via
Ansible - is working perfectly fine.

---

**Last but not least...**

This issue is sorted by installing
[mysqlclient](https://github.com/PyMySQL/mysqlclient-python/) - which is a
fork of MySQLdb - via pip.

### 2) Packages for Ubuntu > 16.04 (fixed)

ProxySQL itself is not providing "up to date" packages for Ubuntu > 16.04.
This Ansible role is working around this by downloading the 16.04 release
for Ubuntu > 16.04 and installing the same (this behavoir might change
in the future).

There is a package dependency for `libcrypto++6` and `libssl1.0.0` starting
from Ubuntu >= 18.04 (which is sorted out automatically).

### 3) Non dynamic global variables

ProxySQL has some `global_variables` which can't be changed during runtime
(see `proxysql_non_dynamic_variables` in [vars/main.yml](vars/main.yml)).
Having said that, this alone is not a problem since this ProxySQL role is
taking care (by generating `proxysql.cnf`) and provides the possibility to
restart automatically if such a variable will change (set
`proxysql_restart_on_static_variables_change` to `True`).

This role is also setting this value in the ProxySQL database itself and
here the problem begins:

If you're changing more than one static variable technically everything is OK.
ProxySQL is restarting and taking the new value from `proxysql.cnf`. But just
the first value is changed in the database itself.

It's not an *"big issue"* since the real value is taken correctly from the
configuration file itself but you'll see a changeset in the next Ansible run
which will:

* Restart ProxySQL once again
* Idempotence tests will fail (if you're not bootstrapping from scratch)

A potential solution could be to not set `proxysql_non_dynamic_variables` in
the ProxySQL database.

### 4) ProxySQL clustering

The ProxySQL clustering is still experimental. A quote from the
[clustering documentation](https://github.com/sysown/proxysql/wiki/ProxySQL-Cluster#configuration-tables):
*"because this feature is still experimental, the table is not automatically
loaded from disk".*

For the initialisation from the `proxysql.cnf` it's important that `hostname`
(obviously) and `port` (it's not taking the default value) are defined.

Testing
-------

[![Build Status](https://travis-ci.org/timorunge/ansible-proxysql.svg?branch=master)](https://travis-ci.org/timorunge/ansible-proxysql)

Tests are done with [Docker](https://www.docker.com) and
[docker_test_runner](https://github.com/timorunge/docker-test-runner) which
brings up the following containers with different environment settings:

* CentOS 7
* Debian 8.10 (Jessie)
* Debian 9.4 (Stretch)
* Ubuntu 14.04 (Trusty Tahr)
* Ubuntu 16.04 (Xenial Xerus)
* Ubuntu 17.10 (Artful Aardvark)
* Ubuntu 18.04 (Bionic Beaver)
* Ubuntu 18.10 (Cosmic Cuttlefish)

Ansible 2.7.0 is installed on all containers and a
[test playbook](tests/test.yml) is getting applied.

For further details and additional checks take a look at the
[docker_test_runner configuration](tests/docker_test_runner.yml) and the
[Docker entrypoint](tests/docker/docker-entrypoint.sh). An high level overview
can be found in the following table:

| Distribution | Version | Repository | Package |
|--------------|---------|------------|---------|
| CentOS       | 7       | yes        | 1.4.11  |
| Debian       | 8.10    | yes        | 1.4.11  |
| Debian       | 9.4     | yes        | 1.4.11  |
| Ubuntu       | 14.04   | yes        | 1.4.11  |
| Ubuntu       | 16.04   | yes        | 1.4.11  |
| Ubuntu       | 17.10   | no         | 1.4.11  |
| Ubuntu       | 18.04   | no         | 1.4.11  |
| Ubuntu       | 18.10   | no         | 1.4.11  |

```sh
# Testing locally:
curl https://raw.githubusercontent.com/timorunge/docker-test-runner/master/install.sh | sh
./docker_test_runner.py -f tests/docker_test_runner.yml
```

Since the build time on Travis is limited for public repositories the
automated tests are limited to:

* CentOS 7
* Debian 8.10 (Jessie)
* Debian 9.4 (Stretch)
* Ubuntu 16.04 (Xenial Xerus)
* Ubuntu 18.04 (Bionic Beaver)

Dependencies
------------

* [proxysql_proxysql_servers.py](https://github.com/timorunge/ansible-proxysql_proxysql_servers)
  which is added to the library folder of this role.

License
-------

BSD

Author Information
------------------

- Timo Runge
