# == Class: networkinterfaces
#
#
#
class networkinterfaces {

  # assure $default_gateway is set
  if $::default_gateway == '' {
    err("The fact default_gateway is missing. Please run puppet again and ensure that plugins are synced to ${::fqdn}.")
  } else {
    concat {
      '/etc/network/interfaces':
        owner  => root,
        group  => root,
        mode   => 644;
    }
    concat::fragment {
      'interfaces header':
        target => '/etc/network/interfaces',
        source => 'puppet:///modules/networkinterfaces/interfaces.head',
        order  => 01;
    }
  }

}
