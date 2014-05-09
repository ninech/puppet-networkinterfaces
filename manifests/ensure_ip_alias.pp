# This defined type is used by networkinterfaces::interface
# You could call this directly, however it is not recommended. IP aliases
# won't be fail- and reboot-safe if not created through networkinterfaces::interface
#
define networkinterfaces::ensure_ip_alias(
    $ensure = present,
    $interface = '',
    $ip = $name
) {

    case $ensure {
        present: {
            exec {
                "/sbin/ip addr add ${ip} dev ${interface}":
                    unless => "/sbin/ip addr ls | /bin/grep ${ip}";
            }
        }
        absent: {
            exec {
                "/sbin/ip addr del ${ip} dev ${interface}":
                    onlyif => "/sbin/ip addr ls | /bin/grep ${ip}";
            }
        }
    }

}
