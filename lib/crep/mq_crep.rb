class MQCrep

  # long32 chamsys  4 bytes
  # word16 version  2 bytes
  # byte seq_fwd    1 byte
  # byte seq_bkwd   1 byte
  # word16 length   2 bytes
  # byte data       1 byte per char

  attr_accessor :host, :port

  def initialize
    @udpSocket = GCDAsyncUdpSocket.alloc.initWithDelegate(self, delegateQueue: Dispatch::Queue.main)
    @commands = { activate: "A", release: "R", test: "T", untest: "U", go: "G", stop: "S", back: "B", forward: "F" }
    
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
    @udpSocket.sendData(data, toHost: host, port: port, withTimeout: -1, tag: 1)

    string
  end

  def sendData(data)
    @udpSocket.sendData(data, toHost: host, port: port, withTimeout: -1, tag: 1)
  end

  def parseCommand(string)
    keywords = %w(test untest go stop select deselect next previous clear locate at red read green blue)
    playback_commands = { :test => 'T', :untest => 'U', :go => 'G', :stop => 'S'}
    
    words = string.downcase.gsub(",","").split(" ")
    
    key_command = (words & keywords).first.to_sym unless (words & keywords).first.nil?
    # TODO: store and test key_command
    # Or wrap the rest of the func in an unless

    case key_command
    when *playback_commands.keys
      command = playback_commands[key_command]
      playback = nil
      words.each do |w|
        int = w.as_number
        playback = int unless int.nil?
      end
      send "#{playback}#{command}" unless command.nil? || playback.nil?
    when :select
      words.reject! { |w| w == "select" }
      channels = get_channels(words)
      channels.each { |c| send "01,#{c},H" }     
    when :deselect
      words.reject! { |w| w == "deselect" }
      channels = get_channels(words)
      channels.each { |c| send "02,#{c},H" } 
    when :next
      send "30H"
    when :previous
      send "31H"
    when :locate
      send "40H"
    when :at
      at_index = words.index { |w| w == "at" }
      unless at_index == 0                                    # only select channels if spoken before intensity
        channels = get_channels(words[0..at_index - 1])
        if channels.count > 0                                 # select channels any channels discovered
          send "03H"    # deselect first
          channels.each { |c| send "01,#{c},H" }
        end
      end
      intensity = get_first_number(words[(at_index + 1)..-1])
      send "05,#{intensity},H"
    when :red
      set_color("red", fromWords: words)
    when :read
      set_color("read", fromWords: words)
    when :green
      set_color("green", fromWords: words)
    when :blue
      set_color("blue", fromWords: words)
    when :clear
      send "09H"
    end


  end

  def get_channels(words)
    channels = []
    thru_strings = %w(through thru threw)
    words.select! { |w| w.as_number != nil || thru_strings.include?(w)}             # ignore anything other than numbers or 'thru'
    # TODO: Tidy up select to automatically select and convert w.as_number (#map?)

    thru_indices = words.each_index.select {|i| thru_strings.include?(words[i])}    # get 'thru' locations
    thru_indices.reverse_each do |i|    # work backwards as array shrinks
      thru = words.slice!(i - 1, 3)                                                 # pluck out 'x thru y' statements
      channels << "#{thru.first.as_number},#{thru.last.as_number}"
    end

    words.each { |w| channels << w.as_number }                                                # get remaining single channels

    channels
  end

  def get_first_number(words)
    words.select { |w| w.as_number != nil }.first.as_number
    # TODO: Tidy up select to grab first as_number value rather than cast, select, first, cast
  end

  def set_color(color, fromWords: words)
    color_index = words.index { |w| w == color }
    unless color_index == 0                                 # only select channels if spoken before value
      channels = get_channels(words[0..color_index - 1])
      if channels.count > 0                                 # select channels any channels discovered
        send "03H"    # deselect first
        channels.each { |c| send "01,#{c},H" }
      end
    end
    value = get_first_number(words[(color_index + 1)..-1])
    col_commands = { 'red' => 16, 'green' => 17, 'blue' => 18, 'read' => 16 }
    send "06,#{col_commands[color]},#{value}H"
  end

end