#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="klyvera"
iso_label="KLYVERA_0_1_0"
iso_publisher="Klyvera"
iso_application="Klyvera live environment"
iso_version="0.1.0"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux'
           'uefi.systemd-boot')
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/sudoers.d/10-klyvera-live"]="0:0:440"
  ["/usr/local/bin/klyvera-live-init"]="0:0:755"
  ["/home/klyvera/.bash_profile"]="1000:1000:644"
  ["/home/klyvera/.config/hypr/hyprland.conf"]="1000:1000:644"
  ["/etc/shadow"]="0:0:400"
)
