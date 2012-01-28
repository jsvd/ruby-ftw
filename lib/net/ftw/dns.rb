require "net/ftw/namespace"
require "socket"

# I didn't really want to write a DNS library.
# The libc methods for dns resolution aren't exactly the most friendly. 
# Not totally sure why Ruby stdlib basically just mirrors that API :(
class Net::FTW::DNS
  V4_IN_V6_PREFIX = "0:" * 12

  # This method is only intended to do A or AAAA lookups
  # I may add PTR lookups later.
  def resolve(hostname)
    official, aliases, family, *addresses = Socket.gethostbyname(hostname)
    # We ignore family, here. Ruby will return v6 *and* v4 addresses in
    # the same gethostbyname() call. It is confusing. 
    #
    # Let's just rely entirely on the length of the address string.
    return addresses.collect do |address|
      if address.length == 16
        unpack_v6(address)
      else
        unpack_v4(address)
      end
    end
  end # def resolve

  private
  def unpack_v4(address)
    return address.unpack("C4").join(".")
  end # def unpack_v4

  private
  def unpack_v6(address)
    if address.length == 16
      # Unpack 16 bit chunks, convert to hex, join with ":"
      address.unpack("n8").collect { |p| p.to_s(16) } \
        .join(":").sub(/(?:0:(?:0:)+)/, "::")
    else 
      # assume ipv4
      # Per the following sites, "::127.0.0.1" is valid and correct
      # http://en.wikipedia.org/wiki/IPv6#IPv4-mapped_IPv6_addresses
      # http://www.tcpipguide.com/free/t_IPv6IPv4AddressEmbedding.htm
      "::" + unpack_v4(address)
    end
  end # def unpack_v6
end # class Net::FTW::DNS
