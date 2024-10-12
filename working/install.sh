#!/bin/bash


#!/usr/bin/env bash

# The files installed by the script conform to the Filesystem Hierarchy Standard:
# https://wiki.linuxfoundation.org/lsb/fhs

# The URL of the script project is:
# https://github.com/XTLS/Xray-install

# The URL of the script is:
# https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh

# If the script executes incorrectly, go to:
# https://github.com/XTLS/Xray-install/issues

# You can set this variable whatever you want in shell session right before running this script by issuing:
# export DAT_PATH='/usr/local/share/xray'
DAT_PATH=${DAT_PATH:-/usr/local/share/xray}

# You can set this variable whatever you want in shell session right before running this script by issuing:
# export JSON_PATH='/usr/local/etc/xray'
JSON_PATH=${JSON_PATH:-/usr/local/etc/xray}

# Set this variable only if you are starting xray with multiple configuration files:
# export JSONS_PATH='/usr/local/etc/xray'

# Set this variable only if you want this script to check all the systemd unit file:
# export check_all_service_files='yes'

# Gobal verbals

if [[ -f '/etc/systemd/system/xray.service' ]] && [[ -f '/usr/local/bin/xray' ]]; then
  XRAY_IS_INSTALLED_BEFORE_RUNNING_SCRIPT=1
else
  XRAY_IS_INSTALLED_BEFORE_RUNNING_SCRIPT=0
fi

# Xray current version
CURRENT_VERSION=''

# Xray latest release version
RELEASE_LATEST=''

# Xray latest prerelease/release version
PRE_RELEASE_LATEST=''

# Xray version will be installed
INSTALL_VERSION=''

# install
INSTALL='0'

# install-geodata
INSTALL_GEODATA='0'

# remove
REMOVE='0'

# help
HELP='0'

# check
CHECK='0'

# --force
FORCE='0'

# --beta
BETA='0'

# --install-user ?
INSTALL_USER=''

# --without-geodata
NO_GEODATA='0'

# --without-logfiles
NO_LOGFILES='0'

# --logrotate
LOGROTATE='0'

# --no-update-service
N_UP_SERVICE='0'

# --reinstall
REINSTALL='0'

# --version ?
SPECIFIED_VERSION=''

# --local ?
LOCAL_FILE=''

# --proxy ?
PROXY=''

# --purge
PURGE='0'

curl() {
  $(type -P curl) -L -q --retry 5 --retry-delay 10 --retry-max-time 60 "$@"
}

systemd_cat_config() {
  if systemd-analyze --help | grep -qw 'cat-config'; then
    systemd-analyze --no-pager cat-config "$@"
    echo
  else
    echo "${aoi}~~~~~~~~~~~~~~~~"
    cat "$@" "$1".d/*
    echo "${aoi}~~~~~~~~~~~~~~~~"
    echo "${red}warning: ${green}The systemd version on the current operating system is too low."
    echo "${red}warning: ${green}Please consider to upgrade the systemd or the operating system.${reset}"
    echo
  fi
}

check_if_running_as_root() {
  # If you want to run as another user, please modify $EUID to be owned by this user
  if [[ "$EUID" -ne '0' ]]; then
    echo "error: You must run this script as root!"
    exit 1
  fi
}

identify_the_operating_system_and_architecture() {
  if [[ "$(uname)" != 'Linux' ]]; then
    echo "error: This operating system is not supported."
    exit 1
  fi
  case "$(uname -m)" in
    'i386' | 'i686')
      MACHINE='32'
      ;;
    'amd64' | 'x86_64')
      MACHINE='64'
      ;;
    'armv5tel')
      MACHINE='arm32-v5'
      ;;
    'armv6l')
      MACHINE='arm32-v6'
      grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm32-v5'
      ;;
    'armv7' | 'armv7l')
      MACHINE='arm32-v7a'
      grep Features /proc/cpuinfo | grep -qw 'vfp' || MACHINE='arm32-v5'
      ;;
    'armv8' | 'aarch64')
      MACHINE='arm64-v8a'
      ;;
    'mips')
      MACHINE='mips32'
      ;;
    'mipsle')
      MACHINE='mips32le'
      ;;
    'mips64')
      MACHINE='mips64'
      lscpu | grep -q "Little Endian" && MACHINE='mips64le'
      ;;
    'mips64le')
      MACHINE='mips64le'
      ;;
    'ppc64')
      MACHINE='ppc64'
      ;;
    'ppc64le')
      MACHINE='ppc64le'
      ;;
    'riscv64')
      MACHINE='riscv64'
      ;;
    's390x')
      MACHINE='s390x'
      ;;
    *)
      echo "error: The architecture is not supported."
      exit 1
      ;;
  esac
  if [[ ! -f '/etc/os-release' ]]; then
    echo "error: Don't use outdated Linux distributions."
    exit 1
  fi
  # Do not combine this judgment condition with the following judgment condition.
  ## Be aware of Linux distribution like Gentoo, which kernel supports switch between Systemd and OpenRC.
  if [[ -f /.dockerenv ]] || grep -q 'docker\|lxc' /proc/1/cgroup && [[ "$(type -P systemctl)" ]]; then
    true
  elif [[ -d /run/systemd/system ]] || grep -q systemd <(ls -l /sbin/init); then
    true
  else
    echo "error: Only Linux distributions using systemd are supported."
    exit 1
  fi
  if [[ "$(type -P apt)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='apt -y --no-install-recommends install'
    PACKAGE_MANAGEMENT_REMOVE='apt purge'
    package_provide_tput='ncurses-bin'
  elif [[ "$(type -P dnf)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='dnf -y install'
    PACKAGE_MANAGEMENT_REMOVE='dnf remove'
    package_provide_tput='ncurses'
  elif [[ "$(type -P yum)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='yum -y install'
    PACKAGE_MANAGEMENT_REMOVE='yum remove'
    package_provide_tput='ncurses'
  elif [[ "$(type -P zypper)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='zypper install -y --no-recommends'
    PACKAGE_MANAGEMENT_REMOVE='zypper remove'
    package_provide_tput='ncurses-utils'
  elif [[ "$(type -P pacman)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='pacman -Syy --noconfirm'
    PACKAGE_MANAGEMENT_REMOVE='pacman -Rsn'
    package_provide_tput='ncurses'
    elif [[ "$(type -P emerge)" ]]; then
    PACKAGE_MANAGEMENT_INSTALL='emerge -qv'
    PACKAGE_MANAGEMENT_REMOVE='emerge -Cv'
    package_provide_tput='ncurses'
  else
    echo "error: The script does not support the package manager in this operating system."
    exit 1
  fi
}

## Demo function for processing parameters
judgment_parameters() {
  local local_install='0'
  local temp_version='0'
  while [[ "$#" -gt '0' ]]; do
    case "$1" in
      'install')
        INSTALL='1'
        ;;
      'install-geodata')
        INSTALL_GEODATA='1'
        ;;
      'remove')
        REMOVE='1'
        ;;
      'help')
        HELP='1'
        ;;
      'check')
        CHECK='1'
        ;;
      '--without-geodata')
        NO_GEODATA='1'
        ;;
      '--without-logfiles')
        NO_LOGFILES='1'
        ;;
      '--purge')
        PURGE='1'
        ;;
      '--version')
        if [[ -z "$2" ]]; then
          echo "error: Please specify the correct version."
          exit 1
        fi
        temp_version='1'
        SPECIFIED_VERSION="$2"
        shift
        ;;
      '-f' | '--force')
        FORCE='1'
        ;;
      '--beta')
        BETA='1'
        ;;
      '-l' | '--local')
        local_install='1'
        if [[ -z "$2" ]]; then
          echo "error: Please specify the correct local file."
          exit 1
        fi
        LOCAL_FILE="$2"
        shift
        ;;
      '-p' | '--proxy')
        if [[ -z "$2" ]]; then
          echo "error: Please specify the proxy server address."
          exit 1
        fi
        PROXY="$2"
        shift
        ;;
      '-u' | '--install-user')
        if [[ -z "$2" ]]; then
          echo "error: Please specify the install user.}"
          exit 1
        fi
        INSTALL_USER="$2"
        shift
        ;;
      '--reinstall')
        REINSTALL='1'
        ;;
      '--no-update-service')
        N_UP_SERVICE='1'
        ;;
      '--logrotate')
        if ! grep -qE '\b([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]\b' <<< "$2";then
          echo "error: Wrong format of time, it should be in the format of 12:34:56, under 10:00:00 should be start with 0, e.g. 01:23:45."
          exit 1
        fi
        LOGROTATE='1'
        LOGROTATE_TIME="$2"
        shift
        ;;
      *)
        echo "$0: unknown option -- -"
        exit 1
        ;;
    esac
    shift
  done
  if ((INSTALL+INSTALL_GEODATA+HELP+CHECK+REMOVE==0)); then
    INSTALL='1'
  elif ((INSTALL+INSTALL_GEODATA+HELP+CHECK+REMOVE>1)); then
    echo 'You can only choose one action.'
    exit 1
  fi
  if [[ "$INSTALL" -eq '1' ]] && ((temp_version+local_install+REINSTALL+BETA>1)); then
    echo "--version,--reinstall,--beta and --local can't be used together."
    exit 1
  fi
}

check_install_user() {
  if [[ -z "$INSTALL_USER" ]]; then
    if [[ -f '/usr/local/bin/xray' ]]; then
      INSTALL_USER="$(grep '^[ '$'\t]*User[ '$'\t]*=' /etc/systemd/system/xray.service | tail -n 1 | awk -F = '{print $2}' | awk '{print $1}')"
      if [[ -z "$INSTALL_USER" ]]; then
        INSTALL_USER='root'
      fi
    else
      INSTALL_USER='nobody'
    fi
  fi
  if ! id "$INSTALL_USER" > /dev/null 2>&1; then
    echo "the user '$INSTALL_USER' is not effective"
    exit 1
  fi
  INSTALL_USER_UID="$(id -u "$INSTALL_USER")"
  INSTALL_USER_GID="$(id -g "$INSTALL_USER")"
}

install_software() {
  package_name="$1"
  file_to_detect="$2"
  type -P "$file_to_detect" > /dev/null 2>&1 && return
  if ${PACKAGE_MANAGEMENT_INSTALL} "$package_name" >/dev/null 2>&1; then
    echo "info: $package_name is installed."
  else
    echo "error: Installation of $package_name failed, please check your network."
    exit 1
  fi
}

get_current_version() {
  # Get the CURRENT_VERSION
  if [[ -f '/usr/local/bin/xray' ]]; then
    CURRENT_VERSION="$(/usr/local/bin/xray -version | awk 'NR==1 {print $2}')"
    CURRENT_VERSION="v${CURRENT_VERSION#v}"
  else
    CURRENT_VERSION=""
  fi
}

get_latest_version() {
  # Get Xray latest release version number
  local tmp_file
  tmp_file="$(mktemp)"
  if ! curl -x "${PROXY}" -sS -H "Accept: application/vnd.github.v3+json" -o "$tmp_file" 'https://api.github.com/repos/XTLS/Xray-core/releases/latest'; then
    "rm" "$tmp_file"
    echo 'error: Failed to get release list, please check your network.'
    exit 1
  fi
  RELEASE_LATEST="$(sed 'y/,/\n/' "$tmp_file" | grep 'tag_name' | awk -F '"' '{print $4}')"
  if [[ -z "$RELEASE_LATEST" ]]; then
    if grep -q "API rate limit exceeded" "$tmp_file"; then
      echo "error: github API rate limit exceeded"
    else
      echo "error: Failed to get the latest release version."
      echo "Welcome bug report:https://github.com/XTLS/Xray-install/issues"
    fi
    "rm" "$tmp_file"
    exit 1
  fi
  "rm" "$tmp_file"
  RELEASE_LATEST="v${RELEASE_LATEST#v}"
  if ! curl -x "${PROXY}" -sS -H "Accept: application/vnd.github.v3+json" -o "$tmp_file" 'https://api.github.com/repos/XTLS/Xray-core/releases'; then
    "rm" "$tmp_file"
    echo 'error: Failed to get release list, please check your network.'
    exit 1
  fi
  local releases_list
  releases_list=($(sed 'y/,/\n/' "$tmp_file" | grep 'tag_name' | awk -F '"' '{print $4}'))
  if [[ "${#releases_list[@]}" -eq '0' ]]; then
    if grep -q "API rate limit exceeded" "$tmp_file"; then
      echo "error: github API rate limit exceeded"
    else
      echo "error: Failed to get the latest release version."
      echo "Welcome bug report:https://github.com/XTLS/Xray-install/issues"
    fi
    "rm" "$tmp_file"
    exit 1
  fi
  local i
  for i in "${!releases_list[@]}"
  do
    releases_list["$i"]="v${releases_list[$i]#v}"
    grep -q "https://ghproxy.cn/https://github.com/XTLS/Xray-core/releases/download/${releases_list[$i]}/Xray-linux-$MACHINE.zip" "$tmp_file" && break
  done
  "rm" "$tmp_file"
  PRE_RELEASE_LATEST="${releases_list[$i]}"
}

version_gt() {
  test "$(echo -e "$1\\n$2" | sort -V | head -n 1)" != "$1"
}

download_xray() {
  DOWNLOAD_LINK="https://ghproxy.cn/https://github.com/XTLS/Xray-core/releases/download/${INSTALL_VERSION}/Xray-linux-${MACHINE}.zip"
  echo "Downloading Xray archive: $DOWNLOAD_LINK"
  if curl -f -x "${PROXY}" -R -H 'Cache-Control: no-cache' -o "$ZIP_FILE" "$DOWNLOAD_LINK"; then
    echo "ok."
  else
    echo 'error: Download failed! Please check your network or try again.'
    return 1
  fi
  echo "Downloading verification file for Xray archive: ${DOWNLOAD_LINK}.dgst"
  if curl -f -x "${PROXY}" -sSR -H 'Cache-Control: no-cache' -o "${ZIP_FILE}.dgst" "${DOWNLOAD_LINK}.dgst"; then
    echo "ok."
  else
    echo 'error: Download failed! Please check your network or try again.'
    return 1
  fi
  if grep 'Not Found' "${ZIP_FILE}.dgst"; then
    echo 'error: This version does not support verification. Please replace with another version.'
    return 1
  fi

  # Verification of Xray archive
  CHECKSUM=$(awk -F '= ' '/256=/ {print $2}' "${ZIP_FILE}.dgst")
  LOCALSUM=$(sha256sum "$ZIP_FILE" | awk '{printf $1}')
  if [[ "$CHECKSUM" != "$LOCALSUM" ]]; then
    echo 'error: SHA256 check failed! Please check your network or try again.'
    return 1
  fi
}

decompression() {
  if ! unzip -q "$1" -d "$TMP_DIRECTORY"; then
    echo 'error: Xray decompression failed.'
    "rm" -r "$TMP_DIRECTORY"
    echo "removed: $TMP_DIRECTORY"
    exit 1
  fi
  echo "info: Extract the Xray package to $TMP_DIRECTORY and prepare it for installation."
}

install_file() {
  NAME="$1"
  if [[ "$NAME" == 'xray' ]]; then
    install -m 755 "${TMP_DIRECTORY}/$NAME" "/usr/local/bin/$NAME"
  elif [[ "$NAME" == 'geoip.dat' ]] || [[ "$NAME" == 'geosite.dat' ]]; then
    install -m 644 "${TMP_DIRECTORY}/$NAME" "${DAT_PATH}/$NAME"
  fi
}

install_xray() {
  # Install Xray binary to /usr/local/bin/ and $DAT_PATH
  install_file xray
  # If the file exists, geoip.dat and geosite.dat will not be installed or updated
  if [[ "$NO_GEODATA" -eq '0' ]] && [[ ! -f "${DAT_PATH}/.undat" ]]; then
    install -d "$DAT_PATH"
    install_file geoip.dat
    install_file geosite.dat
    GEODATA='1'
  fi

  # Install Xray configuration file to $JSON_PATH
  # shellcheck disable=SC2153
  if [[ -z "$JSONS_PATH" ]] && [[ ! -d "$JSON_PATH" ]]; then
    install -d "$JSON_PATH"
    echo "{}" > "${JSON_PATH}/config.json"
    CONFIG_NEW='1'
  fi

  # Install Xray configuration file to $JSONS_PATH
  if [[ -n "$JSONS_PATH" ]] && [[ ! -d "$JSONS_PATH" ]]; then
    install -d "$JSONS_PATH"
    for BASE in 00_log 01_api 02_dns 03_routing 04_policy 05_inbounds 06_outbounds 07_transport 08_stats 09_reverse; do
      echo '{}' > "${JSONS_PATH}/${BASE}.json"
    done
    CONFDIR='1'
  fi

  # Used to store Xray log files
  if [[ "$NO_LOGFILES" -eq '0' ]]; then
    if [[ ! -d '/var/log/xray/' ]]; then
      install -d -m 700 -o "$INSTALL_USER_UID" -g "$INSTALL_USER_GID" /var/log/xray/
      install -m 600 -o "$INSTALL_USER_UID" -g "$INSTALL_USER_GID" /dev/null /var/log/xray/access.log
      install -m 600 -o "$INSTALL_USER_UID" -g "$INSTALL_USER_GID" /dev/null /var/log/xray/error.log
      LOG='1'
    else
      chown -R "$INSTALL_USER_UID:$INSTALL_USER_GID" /var/log/xray/
    fi
  fi
}

install_startup_service_file() {
  mkdir -p '/etc/systemd/system/xray.service.d'
  mkdir -p '/etc/systemd/system/xray@.service.d/'
  local temp_CapabilityBoundingSet="CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE"
  local temp_AmbientCapabilities="AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE"
  local temp_NoNewPrivileges="NoNewPrivileges=true"
  if [[ "$INSTALL_USER_UID" -eq '0' ]]; then
    temp_CapabilityBoundingSet="#${temp_CapabilityBoundingSet}"
    temp_AmbientCapabilities="#${temp_AmbientCapabilities}"
    temp_NoNewPrivileges="#${temp_NoNewPrivileges}"
  fi
cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=$INSTALL_USER
${temp_CapabilityBoundingSet}
${temp_AmbientCapabilities}
${temp_NoNewPrivileges}
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/xray@.service <<EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=$INSTALL_USER
${temp_CapabilityBoundingSet}
${temp_AmbientCapabilities}
${temp_NoNewPrivileges}
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/%i.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
  chmod 644 /etc/systemd/system/xray.service /etc/systemd/system/xray@.service
  if [[ -n "$JSONS_PATH" ]]; then
    "rm" '/etc/systemd/system/xray.service.d/10-donot_touch_single_conf.conf' \
      '/etc/systemd/system/xray@.service.d/10-donot_touch_single_conf.conf'
    echo "# In case you have a good reason to do so, duplicate this file in the same directory and make your customizes there.
# Or all changes you made will be lost!  # Refer: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -confdir $JSONS_PATH" |
      tee '/etc/systemd/system/xray.service.d/10-donot_touch_multi_conf.conf' > \
        '/etc/systemd/system/xray@.service.d/10-donot_touch_multi_conf.conf'
  else
    "rm" '/etc/systemd/system/xray.service.d/10-donot_touch_multi_conf.conf' \
      '/etc/systemd/system/xray@.service.d/10-donot_touch_multi_conf.conf'
    echo "# In case you have a good reason to do so, duplicate this file in the same directory and make your customizes there.
# Or all changes you made will be lost!  # Refer: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -config ${JSON_PATH}/config.json" > \
      '/etc/systemd/system/xray.service.d/10-donot_touch_single_conf.conf'
    echo "# In case you have a good reason to do so, duplicate this file in the same directory and make your customizes there.
# Or all changes you made will be lost!  # Refer: https://www.freedesktop.org/software/systemd/man/systemd.unit.html
[Service]
ExecStart=
ExecStart=/usr/local/bin/xray run -config ${JSON_PATH}/%i.json" > \
      '/etc/systemd/system/xray@.service.d/10-donot_touch_single_conf.conf'
  fi
  echo "info: Systemd service files have been installed successfully!"
  echo "${red}warning: ${green}The following are the actual parameters for the xray service startup."
  echo "${red}warning: ${green}Please make sure the configuration file path is correctly set.${reset}"
  systemd_cat_config /etc/systemd/system/xray.service
  # shellcheck disable=SC2154
  if [[ "${check_all_service_files:0:1}" = 'y' ]]; then
    echo
    echo
    systemd_cat_config /etc/systemd/system/xray@.service
  fi
  systemctl daemon-reload
  SYSTEMD='1'
}

start_xray() {
  if [[ -f '/etc/systemd/system/xray.service' ]]; then
    systemctl start "${XRAY_CUSTOMIZE:-xray}"
    sleep 1s
    if systemctl -q is-active "${XRAY_CUSTOMIZE:-xray}"; then
      echo 'info: Start the Xray service.'
    else
      echo 'error: Failed to start Xray service.'
      exit 1
    fi
  fi
}

stop_xray() {
  XRAY_CUSTOMIZE="$(systemctl list-units | grep 'xray@' | awk -F ' ' '{print $1}')"
  if [[ -z "$XRAY_CUSTOMIZE" ]]; then
    local xray_daemon_to_stop='xray.service'
  else
    local xray_daemon_to_stop="$XRAY_CUSTOMIZE"
  fi
  if ! systemctl stop "$xray_daemon_to_stop"; then
    echo 'error: Stopping the Xray service failed.'
    exit 1
  fi
  echo 'info: Stop the Xray service.'
}

install_with_logrotate() {
  install_software 'logrotate' 'logrotate'
  if [[ -z "$LOGROTATE_TIME" ]]; then
  LOGROTATE_TIME="00:00:00"
  fi
  cat <<EOF > /etc/systemd/system/logrotate@.service
[Unit]
Description=Rotate log files
Documentation=man:logrotate(8)

[Service]
Type=oneshot
ExecStart=/usr/sbin/logrotate /etc/logrotate.d/%i
EOF
  cat <<EOF > /etc/systemd/system/logrotate@.timer
[Unit]
Description=Run logrotate for %i logs

[Timer]
OnCalendar=*-*-* $LOGROTATE_TIME
Persistent=true

[Install]
WantedBy=timers.target
EOF
  if [[ ! -d '/etc/logrotate.d/' ]]; then
      install -d -m 700 -o "$INSTALL_USER_UID" -g "$INSTALL_USER_GID" /etc/logrotate.d/
      LOGROTATE_DIR='1'
  fi
  cat << EOF > /etc/logrotate.d/xray
/var/log/xray/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0600 $INSTALL_USER_UID $INSTALL_USER_GID
}
EOF
  LOGROTATE_FIN='1'
}

install_geodata() {
  download_geodata() {
    if ! curl -x "${PROXY}" -R -H 'Cache-Control: no-cache' -o "${dir_tmp}/${2}" "${1}"; then
      echo 'error: Download failed! Please check your network or try again.'
      exit 1
    fi
    if ! curl -x "${PROXY}" -R -H 'Cache-Control: no-cache' -o "${dir_tmp}/${2}.sha256sum" "${1}.sha256sum"; then
      echo 'error: Download failed! Please check your network or try again.'
      exit 1
    fi
  }
  local download_link_geoip="https://ghproxy.cn/https://github.com/v2fly/geoip/releases/latest/download/geoip.dat"
  local download_link_geosite="https://ghproxy.cn/https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat"
  local file_ip='geoip.dat'
  local file_dlc='dlc.dat'
  local file_site='geosite.dat'
  local dir_tmp
  dir_tmp="$(mktemp -d)"
  [[ "$XRAY_IS_INSTALLED_BEFORE_RUNNING_SCRIPT" -eq '0' ]] && echo "warning: Xray was not installed"
  download_geodata $download_link_geoip $file_ip
  download_geodata $download_link_geosite $file_dlc
  cd "${dir_tmp}" || exit
  for i in "${dir_tmp}"/*.sha256sum; do
    if ! sha256sum -c "${i}"; then
      echo 'error: Check failed! Please check your network or try again.'
      exit 1
    fi
  done
  cd - > /dev/null || exit 1
  install -d "$DAT_PATH"
  install -m 644 "${dir_tmp}"/${file_dlc} "${DAT_PATH}"/${file_site}
  install -m 644 "${dir_tmp}"/${file_ip} "${DAT_PATH}"/${file_ip}
  rm -r "${dir_tmp}"
  exit 0
}

check_update() {
  if [[ "$XRAY_IS_INSTALLED_BEFORE_RUNNING_SCRIPT" -eq '1' ]]; then
    get_current_version
    echo "info: The current version of Xray is $CURRENT_VERSION ."
  else
    echo 'warning: Xray is not installed.'
  fi
  get_latest_version
  echo "info: The latest release version of Xray is $RELEASE_LATEST ."
  echo "info: The latest pre-release/release version of Xray is $PRE_RELEASE_LATEST ."
  exit 0
}

remove_xray() {
  if systemctl list-unit-files | grep -qw 'xray'; then
    if [[ -n "$(pidof xray)" ]]; then
      stop_xray
    fi
    local delete_files=('/usr/local/bin/xray' '/etc/systemd/system/xray.service' '/etc/systemd/system/xray@.service' '/etc/systemd/system/xray.service.d' '/etc/systemd/system/xray@.service.d')
    [[ -d "$DAT_PATH" ]] && delete_files+=("$DAT_PATH")
    [[ -f '/etc/logrotate.d/xray' ]] && delete_files+=('/etc/logrotate.d/xray')
    if [[ "$PURGE" -eq '1' ]]; then
      if [[ -z "$JSONS_PATH" ]]; then
        delete_files+=("$JSON_PATH")
      else
        delete_files+=("$JSONS_PATH")
      fi
      [[ -d '/var/log/xray' ]] && delete_files+=('/var/log/xray')
      [[ -f '/etc/systemd/system/logrotate@.service' ]] && delete_files+=('/etc/systemd/system/logrotate@.service')
      [[ -f '/etc/systemd/system/logrotate@.timer' ]] && delete_files+=('/etc/systemd/system/logrotate@.timer')
    fi
    systemctl disable xray
    if [[ -f '/etc/systemd/system/logrotate@.timer' ]] ; then
      if ! systemctl stop logrotate@xray.timer && systemctl disable logrotate@xray.timer ; then
        echo 'error: Stopping and disabling the logrotate service failed.'
        exit 1
      fi
      echo 'info: Stop and disable the logrotate service.'
    fi
    if ! ("rm" -r "${delete_files[@]}"); then
      echo 'error: Failed to remove Xray.'
      exit 1
    else
      for i in "${!delete_files[@]}"
      do
        echo "removed: ${delete_files[$i]}"
      done
      systemctl daemon-reload
      echo "You may need to execute a command to remove dependent software: $PACKAGE_MANAGEMENT_REMOVE curl unzip"
      echo 'info: Xray has been removed.'
      if [[ "$PURGE" -eq '0' ]]; then
        echo 'info: If necessary, manually delete the configuration and log files.'
        if [[ -n "$JSONS_PATH" ]]; then
          echo "info: e.g., $JSONS_PATH and /var/log/xray/ ..."
        else
          echo "info: e.g., $JSON_PATH and /var/log/xray/ ..."
        fi
      fi
      exit 0
    fi
  else
    echo 'error: Xray is not installed.'
    exit 1
  fi
}

# Explanation of parameters in the script
show_help() {
  echo "usage: $0 ACTION [OPTION]..."
  echo
  echo 'ACTION:'
  echo '  install                   Install/Update Xray'
  echo '  install-geodata           Install/Update geoip.dat and geosite.dat only'
  echo '  remove                    Remove Xray'
  echo '  help                      Show help'
  echo '  check                     Check if Xray can be updated'
  echo 'If no action is specified, then install will be selected'
  echo
  echo 'OPTION:'
  echo '  install:'
  echo '    --version                 Install the specified version of Xray, e.g., --version v1.0.0'
  echo '    -f, --force               Force install even though the versions are same'
  echo '    --beta                    Install the pre-release version if it is exist'
  echo '    -l, --local               Install Xray from a local file'
  echo '    -p, --proxy               Download through a proxy server, e.g., -p http://127.0.0.1:8118 or -p socks5://127.0.0.1:1080'
  echo '    -u, --install-user        Install Xray in specified user, e.g, -u root'
  echo '    --reinstall               Reinstall current Xray version'
  echo "    --no-update-service       Don't change service files if they are exist"
  echo "    --without-geodata         Don't install/update geoip.dat and geosite.dat"
  echo "    --without-logfiles        Don't install /var/log/xray"
  echo "    --logrotate [time]        Install with logrotate."
  echo "                              [time] need be in the format of 12:34:56, under 10:00:00 should be start with 0, e.g. 01:23:45."
  echo '  install-geodata:'
  echo '    -p, --proxy               Download through a proxy server'
  echo '  remove:'
  echo '    --purge                   Remove all the Xray files, include logs, configs, etc'
  echo '  check:'
  echo '    -p, --proxy               Check new version through a proxy server'
  exit 0
}

main() {
  check_if_running_as_root
  identify_the_operating_system_and_architecture
  judgment_parameters "$@"

  install_software "$package_provide_tput" 'tput'
  red=$(tput setaf 1)
  green=$(tput setaf 2)
  aoi=$(tput setaf 6)
  reset=$(tput sgr0)

  # Parameter information
  [[ "$HELP" -eq '1' ]] && show_help
  [[ "$CHECK" -eq '1' ]] && check_update
  [[ "$REMOVE" -eq '1' ]] && remove_xray
  [[ "$INSTALL_GEODATA" -eq '1' ]] && install_geodata

  # Check if the user is effective
  check_install_user

  # Check Logrotate after Check User
  [[ "$LOGROTATE" -eq '1' ]] && install_with_logrotate

  # Two very important variables
  TMP_DIRECTORY="$(mktemp -d)"
  ZIP_FILE="${TMP_DIRECTORY}/Xray-linux-$MACHINE.zip"

  # Install Xray from a local file, but still need to make sure the network is available
  if [[ -n "$LOCAL_FILE" ]]; then
    echo 'warn: Install Xray from a local file, but still need to make sure the network is available.'
    echo -n 'warn: Please make sure the file is valid because we cannot confirm it. (Press any key) ...'
    read -r
    install_software 'unzip' 'unzip'
    decompression "$LOCAL_FILE"
  else
    get_current_version
    if [[ "$REINSTALL" -eq '1' ]]; then
      if [[ -z "$CURRENT_VERSION" ]]; then
        echo "error: Xray is not installed"
        exit 1
      fi
      INSTALL_VERSION="$CURRENT_VERSION"
      echo "info: Reinstalling Xray $CURRENT_VERSION"
    elif [[ -n "$SPECIFIED_VERSION" ]]; then
      SPECIFIED_VERSION="v${SPECIFIED_VERSION#v}"
      if [[ "$CURRENT_VERSION" == "$SPECIFIED_VERSION" ]] && [[ "$FORCE" -eq '0' ]]; then
        echo "info: The current version is same as the specified version. The version is $CURRENT_VERSION ."
        exit 0
      fi
      INSTALL_VERSION="$SPECIFIED_VERSION"
      echo "info: Installing specified Xray version $INSTALL_VERSION for $(uname -m)"
    else
      install_software 'curl' 'curl'
      get_latest_version
      if [[ "$BETA" -eq '0' ]]; then
        INSTALL_VERSION="$RELEASE_LATEST"
      else
        INSTALL_VERSION="$PRE_RELEASE_LATEST"
      fi
      if ! version_gt "$INSTALL_VERSION" "$CURRENT_VERSION" && [[ "$FORCE" -eq '0' ]]; then
        echo "info: No new version. The current version of Xray is $CURRENT_VERSION ."
        # exit 0
      fi
      echo "info: Installing Xray $INSTALL_VERSION for $(uname -m)"
    fi
    install_software 'curl' 'curl'
    install_software 'unzip' 'unzip'
    if ! download_xray; then
      "rm" -r "$TMP_DIRECTORY"
      echo "removed: $TMP_DIRECTORY"
      exit 1
    fi
    decompression "$ZIP_FILE"
  fi

  # Determine if Xray is running
  if systemctl list-unit-files | grep -qw 'xray'; then
    if [[ -n "$(pidof xray)" ]]; then
      stop_xray
      XRAY_RUNNING='1'
    fi
  fi
  install_xray
  [[ "$N_UP_SERVICE" -eq '1' && -f '/etc/systemd/system/xray.service' ]] || install_startup_service_file
  echo 'installed: /usr/local/bin/xray'
  # If the file exists, the content output of installing or updating geoip.dat and geosite.dat will not be displayed
  if [[ "$GEODATA" -eq '1' ]]; then
    echo "installed: ${DAT_PATH}/geoip.dat"
    echo "installed: ${DAT_PATH}/geosite.dat"
  fi
  if [[ "$CONFIG_NEW" -eq '1' ]]; then
    echo "installed: ${JSON_PATH}/config.json"
  fi
  if [[ "$CONFDIR" -eq '1' ]]; then
    echo "installed: ${JSON_PATH}/00_log.json"
    echo "installed: ${JSON_PATH}/01_api.json"
    echo "installed: ${JSON_PATH}/02_dns.json"
    echo "installed: ${JSON_PATH}/03_routing.json"
    echo "installed: ${JSON_PATH}/04_policy.json"
    echo "installed: ${JSON_PATH}/05_inbounds.json"
    echo "installed: ${JSON_PATH}/06_outbounds.json"
    echo "installed: ${JSON_PATH}/07_transport.json"
    echo "installed: ${JSON_PATH}/08_stats.json"
    echo "installed: ${JSON_PATH}/09_reverse.json"
  fi
  if [[ "$LOG" -eq '1' ]]; then
    echo 'installed: /var/log/xray/'
    echo 'installed: /var/log/xray/access.log'
    echo 'installed: /var/log/xray/error.log'
  fi
  if [[ "$LOGROTATE_FIN" -eq '1' ]]; then
    echo 'installed: /etc/systemd/system/logrotate@.service'
    echo 'installed: /etc/systemd/system/logrotate@.timer'
    if [[ "$LOGROTATE_DIR" -eq '1' ]]; then
    echo 'installed: /etc/logrotate.d/'
    fi
    echo 'installed: /etc/logrotate.d/xray'
    systemctl start logrotate@xray.timer
    systemctl enable logrotate@xray.timer
    sleep 1s
    if systemctl -q is-active logrotate@xray.timer; then
      echo "info: Enable and start the logrotate@xray.timer service"
    else
      echo "warning: Failed to enable and start the logrotate@xray.timer service"
    fi
  fi
  if [[ "$SYSTEMD" -eq '1' ]]; then
    echo 'installed: /etc/systemd/system/xray.service'
    echo 'installed: /etc/systemd/system/xray@.service'
  fi
  "rm" -r "$TMP_DIRECTORY"
  echo "removed: $TMP_DIRECTORY"
  get_current_version
  echo "info: Xray $CURRENT_VERSION is installed."
  echo "You may need to execute a command to remove dependent software: $PACKAGE_MANAGEMENT_REMOVE curl unzip"
  if [[ "$XRAY_IS_INSTALLED_BEFORE_RUNNING_SCRIPT" -eq '1' ]] && [[ "$FORCE" -eq '0' ]] && [[ "$REINSTALL" -eq '0' ]]; then
    [[ "$XRAY_RUNNING" -eq '1' ]] && start_xray
  else
    systemctl start xray
    systemctl enable xray
    sleep 1s
    if systemctl -q is-active xray; then
      echo "info: Enable and start the Xray service"
    else
      echo "warning: Failed to enable and start the Xray service"
    fi
  fi
}

main "$@"


#!/bin/bash

# /usr/local/etc/xray/config.json 的目标路径
config_path="/usr/local/etc/xray/config.json"

# 检查文件是否存在，如果存在则删除
if [ -f "$config_path" ]; then
    rm -f "$config_path"
    echo "已删除现有的 $config_path 文件。"
fi

# 创建新的 config.json 内容
config_content=$(cat <<EOF
{
  "log": null,
  "routing": {
    "rules": [
      {
        "inboundTag": [
          "api"
        ],
        "outboundTag": "api",
        "type": "field"
      },
      {
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "blocked",
        "type": "field"
      },
      {
        "outboundTag": "blocked",
        "protocol": [
          "bittorrent"
        ],
        "type": "field"
      }
    ]
  },
  "dns": null,
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 62789,
      "protocol": "dokodemo-door",
      "settings": {
        "address": "127.0.0.1"
      },
      "streamSettings": null,
      "tag": "api",
      "sniffing": null
    },
    {
      "listen": "0.0.0.0",
      "port": 1116,
      "protocol": "shadowsocks",
      "settings": {
        "method": "aes-256-gcm",
        "password": "112233",
        "network": "tcp,udp"
      },
      "streamSettings": null,
      "tag": "inbound-ss",
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "transport": null,
  "policy": {
    "system": {
      "statsInboundDownlink": true,
      "statsInboundUplink": true
    }
  },
  "api": {
    "services": [
      "HandlerService",
      "LoggerService",
      "StatsService"
    ],
    "tag": "api"
  },
  "stats": {},
  "reverse": null,
  "fakeDns": null
}
EOF
)


# 确保 /usr/local/etc/xray/ 目录存在
mkdir -p /usr/local/etc/xray/

# 创建新的 config.json 文件
echo "$config_content" > "$config_path"
echo "default配置已创建并保存到 $config_path"


# 重新启动 xray 服务
killall xray
systemctl restart xray

# 检查服务状态
if [ $? -eq 0 ]; then
    echo "xray 服务已成功重启。"
else
    echo "xray 服务重启失败，请检查配置文件和服务状态。"
fi



# 设置 PATH
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # 无颜色

# 检查是否为 root 用户
rootness() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}必须使用 root 账号运行!${NC}" 1>&2
        exit 1
    fi
}


# 检查IP转发是否已开启 
if sysctl -n net.ipv4.ip_forward | grep -q '1'; then 
    echo -e "${GREEN}IP转发已开启，无需添加设置${NC}" 
else 
    # 添加IP转发设置到 /etc/sysctl.conf 
    if ! grep -q '^net.ipv4.ip_forward=1' /etc/sysctl.conf; then 
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf 
    fi 
 
    # 立即应用设置 
    if sysctl -w net.ipv4.ip_forward=1 && sysctl -p; then 
        echo -e "${GREEN}IP转发已成功开启${NC}" 
    else 
        echo -e "${RED}IP转发开启失败${NC}" 
    fi 
fi 
 
# 检查并启用Google BBR 
if sysctl net.ipv4.tcp_congestion_control | grep -q 'bbr'; then 
    echo -e "${GREEN}BBR 已启用，无需再次设置${NC}" 
else 
    # 启用 BBR 
    if ! grep -q '^net.core.default_qdisc=fq' /etc/sysctl.conf; then 
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf 
    fi 
    if ! grep -q '^net.ipv4.tcp_congestion_control=bbr' /etc/sysctl.conf; then 
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf 
    fi 
 
    # 立即应用 BBR 设置 
    if sysctl -w net.core.default_qdisc=fq && sysctl -w net.ipv4.tcp_congestion_control=bbr && sysctl -p; then 
        echo -e "${GREEN}BBR 已成功启用${NC}" 
    else 
        echo -e "${RED}BBR 启用失败${NC}" 
    fi 
fi  


# 检查 TUN/TAP 设备
tunavailable() {
    if [[ ! -e /dev/net/tun ]]; then
        echo -e "${RED}TUN/TAP 设备不可用!${NC}" 1>&2
        exit 1
    fi
}

# 禁用 SELinux
disable_selinux() {
    if command -v selinuxenabled > /dev/null 2>&1 && selinuxenabled; then
        echo -e "${YELLOW}SELinux 已启用，正在禁用中...${NC}"
        setenforce 0
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    fi
}


# L2TP 预安装信息
preinstall_l2tp() {
    iprange="192.168.43"
    mypsk="hm123456"
    echo "                                                    ______                   _                     
   /\                                              (_____ \                 (_)               _    
  /  \   _ _ _   ____   ___   ___   ____    ____    _____) )  ____   ___     _   ____   ____ | |_  
 / /\ \ | | | | / _  ) /___) / _ \ |    \  / _  )  |  ____/  / ___) / _ \   | | / _  ) / ___)|  _) 
| |__| || | | |( (/ / |___ || |_| || | | |( (/ /   | |      | |    | |_| |  | |( (/ / ( (___ | |__ 
|______| \____| \____)(___/  \___/ |_|_|_| \____)  |_|      |_|     \___/  _| | \____) \____) \___)
                                                                          (__/                     "
}

# 安装 L2TP 及相关依赖
install_l2tp() {
    apt -y install ppp strongswan xl2tpd iptables
    config_install
}

# 配置 L2TP/IPsec
config_install() {
    cat > /etc/ipsec.conf <<EOF
version 2.0


config setup
    protostack=netkey
    nhelpers=8 # 定义使用 8 个额外的 helper 线程来处理加密和解密操作。
    uniqueids=yes # 允许同一个用户（IP地址）发起多个并发的连接。如果设置为 "yes"，旧连接将会在新的连接建立时被终止。
    interfaces=%defaultroute
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!${iprange}.0/24
    
conn l2tp-psk # 定义一个 L2TP-PSK（预共享密钥）连接配置。
    rightsubnet=vhost:%priv # 远程子网设置为虚拟主机模式，%priv 表示远程对端使用私有地址。
    also=l2tp-psk-nonat # 引用另一个连接块 "l2tp-psk-nonat" 中的设置，以减少重复代码。
    
conn l2tp-psk-nonat # 另一个连接块，定义 L2TP-PSK 连接的具体设置。
    authby=secret # 使用预共享密钥 (PSK) 进行身份验证。
    pfs=no # 禁用完全前向保密 (PFS)，减少加密复杂度和资源开销，提升性能。
    auto=add # 该连接会在 IPsec 服务启动时自动加载并尝试建立连接。
    keyingtries=3 # 在连接失败时重试密钥协商的次数，设置为 3 次重试。
    rekey=yes # 启用密钥重新协商。当密钥有效期到达时，将自动重新协商新的密钥。
    ikelifetime=72h # IKE（Internet Key Exchange）密钥的生存时间，设置为 24 小时，减少频繁的重新协商。
    keylife=72h # IPSec 安全关联 (SA) 的密钥生存时间，设置为 24 小时。
    type=transport # 使用传输模式 (transport mode)，这种模式只加密数据的有效负载，不加密整个 IP 数据包头。
    left=%defaultroute # 本地 IP 地址使用默认路由接口上的地址。
    leftid=${IP} # 本地身份标识符，设置为本地的 IP 地址。
    leftprotoport=17/%any # 定义本地使用的协议和端口号，17 表示 UDP 协议，1701 是 L2TP 使用的端口。
    right=%any # 远程对端的 IP 地址，%any 表示可以接受任何远程地址的连接。
    rightprotoport=17/%any # 远程对端的协议和端口号，17 表示 UDP 协议，%any 表示可以接受任何远程端口号。
    dpddelay=60 # Dead Peer Detection (DPD) 的检测间隔时间，设置为 60 秒，每 60 秒发送一次检测包。
    dpdtimeout=60 # 如果 60 秒内没有收到远程对端的 DPD 响应，认为对端失联。
    dpdaction=clear # 在检测到对端失联后，自动重启连接，确保连接可以自动恢复。
EOF

    cat > /etc/ipsec.secrets <<EOF
%any %any : PSK "${mypsk}"
EOF

    cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
port = 1701
[lns default]
ip range = ${iprange}.2-${iprange}.254
local ip = ${iprange}.1
require chap = no
refuse pap = no
require authentication = no
name = l2tpd
ppp debug = no 
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

    cat > /etc/ppp/options.xl2tpd <<EOF
ipcp-accept-local
ipcp-accept-remote
ms-dns 8.8.8.8
ms-dns 1.1.1.1
auth
noccp
mtu 1400
mru 1400
nodefaultroute
connect-delay 0
EOF

    rm -f /etc/ppp/chap-secrets
    cat > /etc/ppp/chap-secrets <<EOF
# Secrets for authentication using CHAP
# client    server    secret    IP addresses
EOF
}


# 最终安装步骤
finally() {
    ipsec verify
    ufw disable
    systemctl enable xl2tpd
    systemctl enable ipsec
    systemctl restart xl2tpd
    systemctl restart ipsec
    echo -e "${GREEN}安装完成${NC}"
}

# 主程序
l2tp() {
    rootness
    tunavailable
    disable_selinux
    preinstall_l2tp
    install_l2tp
    finally
}

# 开始执行
l2tp

# 防火墙和 NAT 配置
iptables -F
iptables -P INPUT ACCEPT
iptables -t nat -A POSTROUTING -j MASQUERADE

echo "vpnuser1     l2tpd     hm123456     192.168.43.3" >> /etc/ppp/chap-secrets
echo "root         l2tpd     hm123456     192.168.43.253" >> /etc/ppp/chap-secrets

cat /etc/ppp/chap-secrets
# 重新启动服务
systemctl restart xl2tpd
systemctl restart ipsec


#!/bin/bash

# Check Root User

# If you want to run as another user, please modify $EUID to be owned by this user
if [[ "$EUID" -ne '0' ]]; then
    echo "$(tput setaf 1)Error: You must run this script as root!$(tput sgr0)"
    exit 1
fi

# Set the desired GitHub repository
repo="go-gost/gost"
base_url="https://api.github.com/repos/$repo/releases"

# Function to download and install gost
install_gost() {

    # Download the binary
    echo "Downloading gost version $version..."
    curl -fSL -o gost.tar.gz "https://oss.yonrd.com/gost_v3/gost_3.0.0-nightly.20241002_linux_amd64.tar.gz"

    # Extract and install the binary
    echo "Installing gost..."
    tar -xzf gost.tar.gz
    chmod +x gost
    mv gost /usr/local/bin/gost

    echo "gost installation completed!"
}

# 开始安装
install_gost

# 检查 gost 是否在运行
if pgrep -x "gost" > /dev/null
then
    echo "gost 正在运行，准备终止..."
    killall gost
    echo "gost 已终止"
else
    echo "gost 未运行，无需终止"
fi

# 提示用户输入IP地址
read -p "请输入要转发的IP地址: " ip_address

# 验证输入是否为有效的IP地址 
if [[ $ip_address =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then 
  echo -e "${GREEN} 输入的IP地址有效：$ip_address${NC}"
else 
  echo -e "${RED} 输入的不是有效的IP地址，请重新运行脚本并输入正确的IP。${NC}"
  exit 1 
fi 

nohup gost -L red://:12345 -F "socks5://admin:@youran12345@$ip_address:8090?so_mark=100&timeout=30s" > gost.log 2>&1 &


echo "gost 已经在后台运行。"

#!/bin/bash

# 获取 eth0 的 IP 地址并将其设置为变量
SERVER_IP=$(ip -o -f inet addr show eth0 | awk '/scope global/ {print $4}')

# 清理 iptables nat 规则
iptables -t nat -F
iptables -t nat -X

# 创建 GOST 链
iptables -t nat -N GOST

# 忽略局域网流量，请根据实际网络环境进行调整
iptables -t nat -A GOST -d $SERVER_IP -j RETURN

# 忽略出口流量
iptables -t nat -A GOST -p tcp -m mark --mark 100 -j RETURN

# 忽略 DNS 流量 (udp 协议的 53 端口)
iptables -t nat -A GOST -p udp --dport 53 -j RETURN

# 重定向 TCP 流量到 12345 端口
iptables -t nat -A GOST -p tcp -j REDIRECT --to-ports 12345

# 拦截局域网流量
iptables -t nat -A PREROUTING -p tcp -j GOST

# 拦截本机流量
iptables -t nat -A OUTPUT -p tcp -j GOST

# 输出提示
echo "iptables 规则已设置完毕，忽略局域网流量的 IP 为：$SERVER_IP"
