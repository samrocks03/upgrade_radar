# frozen_string_literal: true

class DnsResolver
  def resolve(host)
    Addrinfo.getaddrinfo(host, nil)
  rescue SocketError => e
    puts "Resolution failed: #{e.message}"
    nil
  end
end
