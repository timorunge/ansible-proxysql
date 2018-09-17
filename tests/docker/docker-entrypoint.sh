#!/bin/sh
set -e

printf "[defaults]\nroles_path=/etc/ansible/roles\n" > /ansible/ansible.cfg
printf "[client]\nhost=127.0.0.1\npassword=admin\nport=6032\nuser=admin\n" > /ansible/.my.cnf

test -z ${proxysql_use_official_repo} && \
  echo "Missing environment variable: proxysql_use_official_repo" && exit 1
(test "${proxysql_use_official_repo}" = "False" && \
  test -z ${proxysql_version}) && \
  echo "Missing environment variable: proxysql_version" && exit 1

if [ ! -f /etc/ansible/lint.zip ]; then
  wget https://github.com/ansible/galaxy-lint-rules/archive/master.zip -O \
  /etc/ansible/lint.zip
  unzip /etc/ansible/lint.zip -d /etc/ansible/lint
fi

ansible-lint -c /etc/ansible/roles/${ansible_role}/.ansible-lint -r \
  /etc/ansible/lint/galaxy-lint-rules-master/rules \
  /etc/ansible/roles/${ansible_role}
ansible-lint -c /etc/ansible/roles/${ansible_role}/.ansible-lint -r \
  /etc/ansible/lint/galaxy-lint-rules-master/rules \
  /ansible/test.yml

ansible-playbook /ansible/test.yml \
  -i /ansible/inventory \
  --syntax-check

ansible-playbook /ansible/test.yml \
  -i /ansible/inventory \
  --connection=local \
  --become \
  -e "{ proxysql_use_official_repo: ${proxysql_use_official_repo} }" \
  -e "{ proxysql_version: ${proxysql_version} }" \
  $(test -z ${travis} && echo "-vvvv")

ansible-playbook /ansible/test.yml \
  -i /ansible/inventory \
  --connection=local \
  --become \
  -e "{ proxysql_use_official_repo: ${proxysql_use_official_repo} }" \
  -e "{ proxysql_version: ${proxysql_version} }" | \
  grep -q "changed=0.*failed=0" && \
  (echo "Idempotence test: pass" && exit 0) || \
  (echo "Idempotence test: fail" && exit 1)

mysql --defaults-file=/ansible/.my.cnf -e "quit" && \
  (echo "ProxySQL connection check: pass" && exit 0) || \
  (echo "ProxySQL connection check: fail" && exit 1)

get_user1_password=$(mysql --defaults-file=/ansible/.my.cnf -s -r -e "select password from mysql_users where username = 'user1'\G" | tail -1 | awk '{print $2'})
test "Passw0rd" = "${get_user1_password}" && \
  (echo "ProxySQL user check: pass" && exit 0) || \
  (echo "ProxySQL user check: fail" && exit 1)
