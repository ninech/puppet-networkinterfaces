# == Class: networkinterfaces::interface
#
# Define a network interface via puppet
#
# === Parameters
#
# [*ensure*]
#   Ensure interface state (Default to: present)
#
# [*enable*]
#   Ensure interface is configured on boot. (Default to: present)
#
# [*int_auto*]
#   Shoud include auto statement. (Default to: true)
#
# [*interface*]
#   Interface name. (Default to: $name)
#
# [*family*]
#   Interface network family. (Default to: inet)
#
# [*arg*]
#   Configuration type. (Default to: static)
#
# [*order*]
#   Position in /etc/network/interfaces. (Default to: 50)
#
# [*ip*]
#   Address to configure.
#
# [*netmask*]
#   Netmask to configure.
#
# [*gateway*]
#   Default gateway to configure.
#
# [*broadcast*]
#   Broadcast address to configure.
#
# [*ip_aliases*]
#   Additional addresses to add.
#
# [*up_commands*]
#   Interface up hooks.
#
# [*post_up_commands*]
#   Interface post up hooks.
#
# [*down_commands*]
#   Interface down hooks.
#
# [*pre_down_commands*]
#   Interface pre down hooks.
#
# [*bond_slaves*]
#   Bonding slave interface.
#
# [*bond_master*]
#   Bonding master interface.
#
# [*bond_primary*]
#   Primary bonding interface.
#
# [*bond_mode*]
#   Bonding mode.
#
# [*bond_miimon*]
#   miimon interval.
#
# [*bond_updelay*]
#   Bonding up delay.
#
# [*bond_downdelay*]
#   Bonding down delay.
#
# [*bond_arp_interval*]
#   Bonding ARP probe interval.
#
# [*bond_arp_ip_target*]
#   Bonding ARP probe target.
#
# [*bond_arp_validate*]
#   Bonding ARP probe validate.
#
# [*bond_lacp_rate*]
#   Bonding transmission rate for LACPDUs. Possible Values: 0 or 1
#
# [*bridge_ports*]
#   Bridge interfaces.
#
# [*bridge_stp*]
#   Bridge stp value.
#
# [*bridge_fd*]
#   Bridge fd value.
#
# [*bridge_maxage*]
#   Bridge max age.
#
# [*vlan_raw_dev*]
#   VLan raw device name.
#
# === Examples
#
# Add ip alias.
#
# networkinterfaces::interface { 'eth0':
#   ip         => $::ipaddress,
#   netmask    => $::netmask,
#   gateway    => $::default_gateway,
#   ip_aliases => [ '1.2.3.4' ];
# }
#
# Setup bonding
#
# networkinterfaces::interface {
#   [ 'eth0', 'eth1' ]:
#     arg         => 'manual',
#     bond_master => 'bond0',
#     order       => '05';
#
#   'bond0':
#     ip           => $::ipaddress,
#     netmask      => $::netmask,
#     gateway      => $::default_gateway,
#     bond_mode    => 1,
#     bond_slaves  => [ 'eth0', 'eth1' ],
#     bond_primary => 'eth0',
#     bond_miimon  => 100;
# }
#
define networkinterfaces::interface (
  # Default API
  $ensure             = present,
  $enable             = present,
  $int_auto           = true,
  $interface          = $name,
  $family             = 'inet',
  $arg                = 'static',
  $order              = '50',
  # Inet(6) API
  $ip                 = undef,
  $netmask            = undef,
  $gateway            = undef,
  $network            = undef,
  $broadcast          = undef,
  $ip_aliases         = [],
  # Up/Down API
  $up_commands        = [],
  $post_up_commands   = [],
  $down_commands      = [],
  $pre_down_commands  = [],
  # DNS API
  $dns_nameservers    = undef,
  $dns_search         = undef,
  # Bond API
  $bond_slaves        = [],
  $bond_master        = undef,
  $bond_primary       = undef,
  $bond_mode          = undef,
  $bond_miimon        = undef,
  $bond_updelay       = undef,
  $bond_downdelay     = undef,
  $bond_arp_interval  = undef,
  $bond_arp_ip_target = undef,
  $bond_arp_validate  = undef,
  $bond_lacp_rate     = undef,
  $bond_xmit_hash_policy = undef,
  # Bridge API
  $bridge_ports       = [],
  $bridge_stp         = off,
  $bridge_fd          = 5,
  $bridge_maxage      = '20',
  # VLan API
  $vlan_raw_dev       = undef,
) {

  include networkinterfaces

  # Validate interface name. Old-school aliases (eth0:1) not allowed
  validate_re($interface, '^[a-z-]*[0-9]*$')

  concat::fragment { "interfaces_${name}":
    ensure  => $enable,
    target  => '/etc/network/interfaces',
    content => template('networkinterfaces/interface.erb'),
    order   => $order;
  }

  $state_grep = "'state UP|state UNKNOWN|NO-CARRIER'"
  if $bond_master {
    $real_ensure = undef
  } else {
    $real_ensure = $ensure
  }

  # activate/deactivate interfaces
  case $real_ensure {
    present: {
      exec {
        "ifup ${name}":
          require => File['/etc/network/interfaces'],
          command => "/sbin/ifup ${interface}",
          unless  => "/sbin/ip -o link show ${interface} | /bin/egrep ${state_grep}";
        "reload interface ${name}":
          command     => "/sbin/ifdown ${interface}; /sbin/ifup ${interface}",
          subscribe   => File["${::concat_basedir}/_etc_network_interfaces/fragments/${order}_interfaces_${name}"],
          refreshonly => true,
          require     => File['/etc/network/interfaces'],
      }
      networkinterfaces::ensure_ip_alias { $ip_aliases:
        interface => $interface;
      }
    }
    absent: {
      exec {
        "ifdown ${name}":
          before  => Exec['concat_/etc/network/interfaces'],
          command => "/sbin/ifdown ${interface}",
          onlyif  => "/sbin/ip addr show | /bin/grep ' ${interface}' | /bin/egrep ${state_grep}";
      }
      networkinterfaces::ensure_ip_alias { $ip_aliases:
        ensure    => absent,
        interface => $interface;
      }
    }
  }

  # install packages if needed
  if $vlan_raw_dev and ( ! defined(Package['vlan']) ) {
    package { 'vlan':
      ensure => present,
      before => Exec['concat_/etc/network/interfaces'];
    }
  }
  if $bridge_ports != [] and ( ! defined(Package['bridge-utils']) ) {
    package { 'bridge-utils':
      ensure => present,
      before => Exec['concat_/etc/network/interfaces'];
    }
  }
  if $bond_slaves != [] and ( ! defined(Package['ifenslave-2.6']) ) {
    package { 'ifenslave-2.6':
      ensure => present,
      before => Exec['concat_/etc/network/interfaces'];
    }
  }
  if $bond_slaves != [] and ( ! defined(Package['ethtool']) ) {
    package { 'ethtool':
      ensure => present,
      before => Exec['concat_/etc/network/interfaces'];
    }
  }

}
