#!/usr/bin/env bash

__install() {

  {
    ip link add name br-ikuai-lan1 type bridge
    ip link set dev br-ikuai-lan1 up
    ip addr flush dev br-ikuai-lan1
    ip addr add 192.168.9.2/24 dev br-ikuai-lan1

    ip link add name br-ikuai-wan1 type bridge
    ip link set dev br-ikuai-wan1 up

  } || true

  _name="ikuai"
  virsh destroy "$_name" >/dev/null 2>&1
  virsh undefine "$_name" >/dev/null 2>&1
  _system_img="/data/vms/ikuai/system.qcow2"

  {
    _source_env="/data/vms/ikuai/source.env"
    set -a
    source "$_source_env" 2>/dev/null
    set +a

    if [[ "${_mac_wan1}" == "" ]]; then
      _mac_wan1=$(openssl rand -hex 5 | sed -e 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/88:\1:\2:\3:\4:\5/')
      echo "_mac_wan1=$_mac_wan1" >>$_source_env
    fi

    if [[ "${_mac_lan1}" == "" ]]; then
      _mac_lan1=$(openssl rand -hex 5 | sed -e 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/88:\1:\2:\3:\4:\5/')
      echo "_mac_lan1=$_mac_lan1" >>$_source_env
    fi
  }

  if [ ! -f "$_system_img" ]; then
    docker run --rm --name="releases" -v /data/vms/ikuai:/target ghcr.nju.edu.cn/ghcr.io/lwmacct/260403-bbiz-vm-ikuai:v3.7.22-qcow2.tar.gz cp /root/iKuai8_x64_3.7.22_qcow2.tar.gz /target
    tar -zxvf /data/vms/ikuai/iKuai8_x64_3.7.22_qcow2.tar.gz -C /data/vms/ikuai
  fi

  virt-install --name="$_name" \
    --memory=4096 \
    --cpu host-passthrough \
    --vcpus $(grep 'processor' /proc/cpuinfo | sort -u | wc -l) \
    --os-type=linux \
    --virt-type=kvm \
    --accelerate \
    --autostart \
    --noautoconsole \
    --import \
    --disk "$_system_img",cache=none,bus=virtio \
    --network bridge=br-ikuai-lan1,model=virtio,mac=$_mac_lan1 \
    --network bridge=br-ikuai-wan1,model=virtio,mac=$_mac_wan1
}

__help() {

  # 使用端口转发来打开 ikuai web 用户名和密码都是默认的 admin/admin
  # socat TCP-LISTEN:8825,reuseaddr,fork TCP:192.168.9.1:80

}
__install
