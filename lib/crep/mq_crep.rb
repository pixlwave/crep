module MQ
  class CREP

    # long32 chamsys  4 bytes
    # word16 version  2 bytes
    # byte seq_fwd    1 byte
    # byte seq_bkwd   1 byte
    # word16 length   2 bytes
    # byte data       1 byte per char

    attr_accessor :host, :port

    def initialize
      @udpSocket = GCDAsyncUdpSocket.alloc.initWithDelegate(self, delegateQueue: Dispatch::Queue.main)
      
      @header = [80, 69, 82, 67, 0, 0]    # P, E, R, C, version 00
      @seq_fwd = Pointer.new(:uchar)
      @seq_bkwd = Pointer.new(:uchar)

      @host = "255.255.255.255"
      @port = 6553
    end

    def send(string)
      @seq_fwd[0] += 1
      length_array = [string.length % 255, string.length / 255]     # little endian so remainder goes first

      bytes = @header + [@seq_fwd[0], @seq_bkwd[0]] + length_array + string.bytes.to_a
      data_string = bytes.pack('C*')
      data = data_string.dataUsingEncoding(NSASCIIStringEncoding)
      
      puts string
      sendData(data)
    end

    def sendData(data)
      @udpSocket.sendData(data, toHost: host, port: port, withTimeout: -1, tag: 1)
    end

  end
end