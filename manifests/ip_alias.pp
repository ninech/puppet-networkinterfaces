# This defined type is used by networkinterfaces::interface
# You could call this directly, however it is not recommended. IP aliases
# won't be fail- and reboot-safe if not created through networkinterfaces::interface
#
define networkinterfaces::ip_alias(
  $interface,
  $ensure    = present,
  $ip        = $name,
  $order     = 50,
) {

  concat::fragment { "interfaces_${interface}_${name}":
    ensure  => $enable,
    target  => '/etc/network/interfaces',
    content => template('networkinterfaces/ip_alias.erb'),
    order   => $order;
  }

}
