#!/opt/rubies/2.4.1/bin/ruby

require 'timeout'
require 'socket'
require 'byebug'

class Tracer
  attr_reader :destination

  def initialize(destination, hops=30)
      @destination = destination
      @hops = hops
      @ttl = 1

      # @port = rand(33434..33535)
      @port = 33510
  end

  def run
      dest_ip = IPSocket.getaddress(@destination)
      puts "traceroute to #{@destination} (#{dest_ip}), #{@hops} hops max"

      while true && @ttl <= @hops
        sender = create_sender
        receiver = create_receiver

        # Packs port and host as an AF_INET/AF_INET6 sockaddr string
        # puts "Sending to #{dest_ip}:#{@port}"
        sender.connect(Socket.pack_sockaddr_in(@port, dest_ip))
        sender.send("Hello", 0)

        begin
          Timeout.timeout(3) {    
            data, addr = receiver.recvfrom(1024)
            puts "#{@ttl} #{addr.ip_address}"

            return if addr.ip_address == dest_ip
          }
        rescue Timeout::Error
          puts "#{@ttl} *"
        end

        receiver.close
        sender.close

        @ttl += 1
      end
  end

  def create_sender
    s = Socket.new(Socket::AF_INET,Socket::SOCK_DGRAM, Socket::IPPROTO_UDP)
    sockaddr = Socket.pack_sockaddr_in('33511', '')
    s.bind(sockaddr)
    s.setsockopt(:IP, :TTL, @ttl)
    return s
  end

  def create_receiver
    s = Socket.new(Socket::AF_INET, Socket::SOCK_RAW, Socket::IPPROTO_ICMP)
    # Packs port and host as an AF_INET/AF_INET6 sockaddr string
    sockaddr = Socket.pack_sockaddr_in('33511', '')
    s.bind(sockaddr)
    return s
  end
end

x = Tracer.new("www.google.com")
# byebug
puts x.run
