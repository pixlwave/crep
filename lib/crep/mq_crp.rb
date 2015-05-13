module MQ
  class CRP

    KEYWORDS = %w(test untest go stop select deselect next previous clear locate at red read green blue)
    PLAYBACK_COMMANDS = { :test => 'T', :untest => 'U', :go => 'G', :stop => 'S'}

    def self.parse(string)
      words = string.downcase.gsub(",","").split(" ")
      
      key_command = (words & KEYWORDS).first.to_sym unless (words & KEYWORDS).first.nil?
      # TODO: store and test key_command
      # Or wrap the rest of the func in an unless

      case key_command
      when *PLAYBACK_COMMANDS.keys
        command = PLAYBACK_COMMANDS[key_command]
        playback = nil
        words.each do |w|
          int = w.as_number
          playback = int unless int.nil?
        end
        ["#{playback}#{command}"] unless command.nil? || playback.nil?
      when :select
        words.reject! { |w| w == "select" }
        channels = get_channels(words)
        channels.map { |c| "01,#{c},H" }     
      when :deselect
        words.reject! { |w| w == "deselect" }
        channels = get_channels(words)
        channels.map { |c| "02,#{c},H" } 
      when :next
        ["30H"]
      when :previous
        ["31H"]
      when :locate
        ["40H"]
      when :at
        at_index = words.index { |w| w == "at" }
        result = []
        unless at_index == 0                                    # only select channels if spoken before intensity
          channels = get_channels(words[0..at_index - 1])
          if channels.count > 0                                 # select channels any channels discovered
            result << "03H"    # deselect first
            channels.each { |c| result << "01,#{c},H" }
            result
          end
        end
        intensity = get_first_number(words[(at_index + 1)..-1])
        result << "05,#{intensity},H"
      when :red
        parse_color("red", fromWords: words)
      when :read
        parse_color("read", fromWords: words)
      when :green
        parse_color("green", fromWords: words)
      when :blue
        parse_color("blue", fromWords: words)
      when :clear
        ["09H"]
      end


    end

    def self.get_channels(words)
      channels = []
      thru_strings = %w(through thru threw)
      words.select! { |w| w.as_number != nil || thru_strings.include?(w)}             # ignore anything other than numbers or 'thru'
      # TODO: Tidy up select to automatically select and convert w.as_number (#map?)

      thru_indices = words.each_index.select {|i| thru_strings.include?(words[i])}    # get 'thru' locations
      thru_indices.reverse_each do |i|    # work backwards as array shrinks
        thru = words.slice!(i - 1, 3)                                                 # pluck out 'x thru y' statements
        channels << "#{thru.first.as_number},#{thru.last.as_number}"
      end

      words.each { |w| channels << w.as_number }                                      # get remaining single channels

      channels
    end

    def self.get_first_number(words)
      words.select { |w| w.as_number != nil }.first.as_number
      # TODO: Tidy up select to grab first as_number value rather than cast, select, first, cast
    end

    def self.parse_color(color, fromWords: words)
      color_index = words.index { |w| w == color }
      result = []
      unless color_index == 0                                 # only select channels if spoken before value
        channels = get_channels(words[0..color_index - 1])
        if channels.count > 0                                 # select channels any channels discovered
          result << "03H"    # deselect first
          channels.each { |c| result << "01,#{c},H" }
        end
      end
      value = get_first_number(words[(color_index + 1)..-1])
      col_commands = { 'red' => 16, 'green' => 17, 'blue' => 18, 'read' => 16 }
      result << "06,#{col_commands[color]},#{value}H"
    end

  end
end