#!/usr/bin/env bash

heroku_exec_log_debug() {
  [ "$HEROKU_EXEC_DEBUG" == "1" ] && echo "[heroku-exec] ${1}"
}

heroku_exec_log_error() {
  ([[ "$DYNO" != *run.* ]] || [ "$HEROKU_EXEC_DEBUG" == "1" ]) && echo "[heroku-exec] ERROR: ${1}"
}

heroku_exec_log_info() {
  ([[ "$DYNO" != *run.* ]] || [ "$HEROKU_EXEC_DEBUG" == "1" ]) && echo "[heroku-exec] ${1}"
}

heroku_exec_open() {
  local localAddr=$1
  local localPort="1092"
  local privateKey="$HOME/.ssh/heroku_exec_rsa"

  mkdir -p $(dirname $privateKey)
  ssh-keygen -f ${privateKey} -t rsa -N '' -C '' > /dev/null 2>&1
  cat << EOF > /tmp/.heroku_exec_data.json
{
  "dyno_key": "$(cat ${privateKey}.pub)",
  "dyno_ip": "${localAddr}",
  "dyno_user": "$(whoami)"
}
EOF

  cat << EOF > $HOME/.ssh/sshd_config
HostKey ${privateKey}
AuthorizedKeysFile $HOME/.ssh/authorized_keys
Subsystem sftp /usr/lib/openssh/sftp-server
ClientAliveInterval 30
ClientAliveCountMax 3
EOF

  if ssh -V 2>&1 | grep -q -e '^OpenSSH_7\.2.*$' -e '^OpenSSH_6\.6.*$'; then
    echo "UsePrivilegeSeparation no" >> $HOME/.ssh/sshd_config
  fi

  if [ -z "$(ps -C sshd -o pid=)" ]; then
    heroku_exec_log_debug "Starting sshd on localhost:${localPort}..."
    /usr/sbin/sshd -f $HOME/.ssh/sshd_config -o "Port ${localPort}"

    if [ $? -ne 0 ]; then
      heroku_exec_log_error "Could not start SSH! Heroku Exec will not be available."
    else
      (
        failures=0
        max_retries=3
        retry_wait=10
        retry_period=10
        start_time=$SECONDS
        while true; do
          iteration_start_time=$SECONDS
          tunnel=$(curl -s -X POST -d @/tmp/.heroku_exec_data.json -H "Content-Type: application/json" -L https://exec-manager.heroku.com:443/api/v2/api/v2/7e81ec1f-a7f0-413f-8c74-3fcab3c4469f)

          echo "$tunnel" | python -c 'import json,sys;obj=json.load(sys.stdin)' > /dev/null 2>&1
          if [ $? != 0 ]; then
            heroku_exec_log_debug "error at=create_tunnel url=https://exec-manager.heroku.com:443/api/v2/api/v2/7e81ec1f-a7f0-413f-8c74-3fcab3c4469f json=$tunnel"
          else
            heroku_exec_log_debug "at=create_tunnel json=$tunnel"
            proxyUser=$(echo "$tunnel" | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["user"])')
            proxyHost=$(echo "$tunnel" | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["host"])')
            proxyPort=$(echo "$tunnel" | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["port"])')
            proxyKey=$(echo "$tunnel" | python -c 'import json,sys;obj=json.load(sys.stdin);print(obj["key"])')

            echo "${proxyKey}" > $HOME/.ssh/proxy_rsa.pub
            heroku_exec_log_debug "at=authorize_pubkey fingerprint=$(ssh-keygen -lf $HOME/.ssh/proxy_rsa.pub)"
            echo "${proxyKey}" >> $HOME/.ssh/authorized_keys
            heroku_exec_log_debug "at=tunnel_starting attempts=${failures} remote_host=${proxyUser}@${proxyHost}:${proxyPort} local_port=${localPort}"
            ssh -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
                -o StrictHostKeyChecking=no -i ${privateKey} \
                -p ${proxyPort} -R 0.0.0.0:0:localhost:${localPort} \
                -q -N ${proxyUser}@${proxyHost} > /dev/null 2>&1

            heroku_exec_log_debug "at=tunnel_exit status=$?"
          fi

          if [ $(($SECONDS - $iteration_start_time)) -lt 30 ]; then
            failures=$((failures+1))
            if [ $failures -gt $max_retries ]; then
              if [ $(($SECONDS - $start_time)) -lt $retry_period ]; then
                heroku_exec_log_error "Could not connect to proxy! Waiting $retry_wait seconds before retry..."
                sleep $retry_wait
                retry_wait=$((retry_wait+10))
              fi
              failures=0
              start_time=$SECONDS
            fi
          else
            sleep 1
          fi
        done
      ) &
      heroku_exec_log_info "Starting"
    fi
  else
    heroku_exec_log_debug "The sshd service is already running"
  fi
}

export_jvm_opts() {
  local ip_addr=${1}
  local jmx_port=${HEROKU_JMX_PORT:-"1098"}
  local rmi_port=${HEROKU_RMI_PORT:-"1099"}

  export HEROKU_JMX_OPTIONS="-Dcom.sun.management.jmxremote \
-Dcom.sun.management.jmxremote.port=${jmx_port} \
-Dcom.sun.management.jmxremote.rmi.port=${rmi_port} \
-Dcom.sun.management.jmxremote.ssl=false \
-Dcom.sun.management.jmxremote.authenticate=false \
-Dcom.sun.management.jmxremote.local.only=true \
-Djava.rmi.server.hostname=${ip_addr} \
-Djava.rmi.server.port=${rmi_port}"

  if [ "$HEROKU_DISABLE_JMX" != "true" ] && [ "$HEROKU_DISABLE_JMX" != "1" ]; then
    export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS} ${HEROKU_JMX_OPTIONS}"
  fi
}

main() {
  local ip_addr="$(ip -4 a show eth0 | grep inet | sed -E -e 's/.*inet //g' | sed -E -e 's/\/[0-9]+.*//g')"
  export_jvm_opts ${ip_addr}
  heroku_exec_open ${ip_addr}
}

main "$@"
