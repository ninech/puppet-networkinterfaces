Facter.add(:default_gateway) do
  confine :kernel => :linux
  setcode do
    if File.exists?("/sbin/ip")
      ipaddress_regex = %r{\d+\.\d+\.\d+\.\d+}
      dev_regex = %r{[a-z0-9]+}
      dev = nil
      ip = nil
      output = %x{/sbin/ip route ls}
      output.split("\n").each do |line|
        next unless line =~ /^default via (#{ipaddress_regex}) dev (#{dev_regex}) /
        ip = $1
        break
      end
      ip
    end
  end
end
