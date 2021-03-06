# Module networkinterfaces

This module manages the file /etc/network/interfaces on Debian based systems
and takes care of taking interfaces up/down if necessary.

## Classes

### networkinterfaces
The base class that initializes concat for the file /etc/network/interfaces.
This class is included by the following defined type and therefore does not
need to be included in any manifest.

## Defined Types

### networkinterfaces::interface
This defines an interface entry in /etc/network/interfaces. 'lo' is already
defined per default. For detailed usage instructions and a list of all
possible variables see networkinterfaces::interface.

## Custom Facts

### default_gateway
This fact gathers the active default gateway out of the output of `ip route show`.

## Copyright

Copyright (c) 2014 Nine Internet Solutions AG. See LICENSE.txt for further details.
