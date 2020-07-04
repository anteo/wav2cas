require 'wav2cas/version'
require 'wavefile'
require 'ostruct'

class Wav2Cas
  Error = Class.new(StandardError)

  def initialize(wav_file, skip_seconds: 0, has_lead_tone: true, auto_align: false, peak_threshold: 10, debug: false)
    @wav_file       = wav_file
    @skip_seconds   = skip_seconds
    @has_lead_tone  = has_lead_tone
    @auto_align     = auto_align
    @peak_threshold = peak_threshold
    @debug          = debug
  end

  def convert_to(cas_file)
    load_samples
    detect_pulse_distance
    proof_pulse_distance

    load_data
    write_cas cas_file
  end

  protected

  def debug(message)
    puts message if @debug
  end

  def message_with_position(message)
    "#{message} at #{"%.3f" % current_timestamp}s, position: #{"%08X" % current_position}"
  end

  def print_sample(pos, size = 40)
    val = ((@samples[pos] / 128.0 - 1) * size).round
    s   = "#{"%05d:%03d" % [pos, @samples[pos]]} "
    neg = [val, 0].min
    pos = [0, val].max
    s   += " " * (size + neg) + "*" * (-neg)
    s   += "|"
    s   += "*" * pos + " " * (size - pos)
    puts s
  end

  def print_samples(start_pos, end_pos)
    (start_pos..end_pos).each { |pos| print_sample(pos) }
  end

  def detect_pulse_distance
    rewind!
    prev_pulse  = nil
    @pulse_dist = 0
    20.times do |i|
      break unless detect_next_pulse
      if prev_pulse
        dist = @last_pulse.pos - prev_pulse.pos
        debug "#{i}th distance between pulses: #{dist}"
        if dist > @pulse_dist
          @pulse_dist = dist
          @start_pos  = @last_pulse.pos
        end
      end
      prev_pulse = @last_pulse
    end
    raise Error, 'Audio is too short or silent' unless @pulse_dist > 0
    debug "Detected pulse distance: #{@pulse_dist}"
  end

  def proof_pulse_distance
    rewind!
    20.times do
      break unless forward!
      unless @last_pulse
        raise Error, "Can't detect clock frequency, please ensure that audio starts from lead tone!"
      end
    end
  end

  def rewind!
    @pos      = @start_pos || (@source_format.sample_rate * @skip_seconds.to_f).floor
    @prev_pos = @pos
  end

  def detect_next_pulse(threshold = 130 + @peak_threshold)
    @pos += 1 while @pos < @n_samples && @samples[@pos] < threshold
    return false if @pos >= @n_samples
    pulse_start = @pos

    @pos        += 1 while @pos < @n_samples && @samples[@pos] >= threshold
    return false if @pos >= @n_samples
    pulse_end = @pos - 1

    pulse       = @samples[pulse_start..pulse_end].each_with_index.max
    @last_pulse = OpenStruct.new(val: pulse[0], pos: pulse[1] + pulse_start)
  end

  def detect_pulse(pos = @pos, distance = @pulse_dist / 6)
    pulse_start = pos - distance
    pulse_end   = pos + distance
    return if pulse_end >= @n_samples

    samples   = @samples[pulse_start..pulse_end]
    max       = samples.each_with_index.max
    min       = samples.each_with_index.min
    has_pulse = max[0] - min[0] > @peak_threshold
    has_pulse && OpenStruct.new(val: max[0], pos: max[1] + pulse_start)
  end

  def load_samples
    @samples = []

    reader = WaveFile::Reader.new(@wav_file)

    @source_format = reader.format
    @target_format = WaveFile::Format.new(:mono, :pcm_8, @source_format.sample_rate)

    reader.each_buffer(10000) do |buffer|
      @samples += buffer.convert(@target_format).samples
    end

    @n_samples = @samples.count
  end

  def forward!
    @prev_pos = @pos
    @pos      += @pulse_dist
    return false if @pos >= @n_samples
    @last_pulse = detect_pulse
    align_to_last_pulse
    true
  end

  def current_timestamp
    @pos / @source_format.sample_rate.to_f
  end

  def current_position
    ((@bits.size - 1) / 8)
  end

  def align_to_last_pulse
    @pos = @last_pulse.pos if @last_pulse
  end

  def load_data
    rewind!
    @bits          = ""
    @has_sync_byte = false
    clock_lost     = false
    loop do
      break unless forward!
      middle_pos = (@pos + @prev_pos) / 2
      has_pulse  = detect_pulse(middle_pos)
      @bits      += has_pulse ? "1" : "0"
      if !@has_sync_byte && @has_lead_tone && @bits[-8..-1] == '10100101'
        @bits          = ("0" * 256) + "10100101"
        @has_sync_byte = true
        unless @auto_align
          @pos += @pulse_dist / 2
          next
        end
      end
      if !@last_pulse
        if @auto_align
          debug message_with_position("Auto-align")
          detect_next_pulse
          align_to_last_pulse
        elsif @has_lead_tone && @has_sync_byte
          clock_lost = true
        end
      elsif clock_lost
        puts message_with_position("Possible read error")
        clock_lost = false
      end
    end
  end

  def write_cas(file_name)
    if @has_lead_tone
      File.write file_name, [@bits].pack("B*")
    else
      8.times do |i|
        File.write file_name + "_#{i + 1}", [@bits].pack("B*")
        @bits.prepend "0"
      end
    end
  end
end
