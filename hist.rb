#!/usr/bin/env -S ruby -W2 -w

require 'optparse'
require 'io/console'
require 'bigdecimal'

_, $width = IO.console.winsize

class TallyMean
  def self.mean(hash)
    total_count = hash.values.sum
    return nil if total_count == 0

    weighted_sum = hash.sum { |val, freq| val * freq }
    (BigDecimal(weighted_sum) / total_count).to_f
  end

  def self.median(hash)
    total_count = hash.values.sum
    return nil if total_count == 0

    sorted = hash.sort_by { |val, _| val }
    midpoint = total_count / 2.0

    count = 0
    sorted.each do |val, freq|
      count += freq
      if total_count.odd?
        return val if count > midpoint.floor
      else
        return val if count > midpoint
        return (val + sorted[sorted.index([val, freq]) + 1][0]) / 2.0 if count == midpoint
      end
    end
  end

  def self.mode(hash)
    return nil if hash.values.empty?

    max_freq = hash.values.max
    hash.select { |_, freq| freq == max_freq }.keys
  end

  def self.geometric_mean(hash)
    total_count = hash.values.sum
    return nil if total_count == 0 || hash.keys.any? { |x| x <= 0 }

    # use logarithmic way to calculate geometric mean
    log_sum = hash.sum { |val, freq| Math.log(val) * freq }
    Math.exp(log_sum / total_count)
  end

  def self.harmonic_mean(hash)
    total_count = hash.values.sum
    return nil if total_count == 0 || hash.keys.any? { |x| x <= 0 }

    (BigDecimal(total_count) / hash.sum { |val, freq| BigDecimal(freq) / val }).to_f
  end

  def self.percentile(hash, percentile)
    # hash { value => count }
    # percentile: decimal between 0 and 1

    sorted = hash.keys.sort

    total = hash.values.sum
    target = percentile * total

    cumulative = 0
    sorted.each do |val|
      cumulative += hash[val]
      return val if cumulative >= target
    end
  end
end

class Histogram
  VERSION = '0.2'

  def parse_options
    @options = {
      block: '▅',
      block_unfilled: ' ',
      foreground: nil,
      background: nil,
      width: ($width * 6 / 10),
    }
    OptionParser.new do |parser|
      parser.separator 'Output a histogram of input data'
      parser.separator ''
      parser.separator 'Options:'
      parser.on('-a', '--ascii', 'Ouput only ASCII characters') {
        @options[:block] = '#'
        @options[:block_unfilled] = ' '
      }
      parser.on('-fg', '--foreground=NUMBER', 'Set foreground color') { |number|
        @options[:foreground] = number
      }

      parser.on('-bg', '--background=NUMBER', 'Set background color') { |number|
        @options[:background] = number
      }
      parser.on('-c', '--cumulative', 'Output cumulative histogram') {
        @options[:cumulative] = true
      }
      parser.on('-w', '--width=WIDTH', 'Max width of output bar') { |width|
        @options[:width] = width.to_i
      }
      parser.on('-0', '--zero', 'Include values with no occurrences') {
        @options[:output_zero] = true
      }
      parser.on('-s', '--output-summary', 'Output summary') {
        @options[:output_summary] = true
      }
      parser.on('-v', '--version', 'Output version') {
        puts "#{ARGV[0]} #{Histogram::VERSION}"
        exit(0)
      }
    end.parse!
  end

  def read_data(io)
    data = Hash.new(0)

    io.each_line { |line|
      data[line.strip.to_i] += 1
    }

    data
  end

  def fill_empty_slots
    return unless @options[:output_zero]

    # fill empty slots
    min, max = @data.keys.minmax
    (min..max).to_a.each { |i| @data[i] = 0 if @data[i] == 0 }
  end

  def output_summary
    return unless @options[:output_summary]

    puts '-' * scale_bar_width(@max_value)
    bar = generate_bar(@max_value)
    percent = '(100.0%)'
    puts "#{' ' * @max_width_key} #{ "%#{@max_width_value}d" % @sum_values} #{percent} #{bar}"
  end

  def set_variables
    @max_width_key = @data.keys.max_by { |k| k.to_s.size }.to_s.size
    @max_width_value = @data.values.max_by { _1.to_s.size }.to_s.size
    @max_value = @data.values.max
    @sum_values = @data.values.sum

    if @options[:cumulative]
      @max_value = @sum_values
      @max_width_value = @max_value.to_s.size
    end
  end

  def color_block(hex)
    r = hex[1..2].to_i(16)
    g = hex[3..4].to_i(16)
    b = hex[5..6].to_i(16)
    "\e[38;2;#{r};#{g};#{b}m"
  end

  def grayness(value)
    "\e[38;2;#{value};#{value};#{value}m"
  end

  def distinct_colors_random_min_light(n, seed: nil, min: 0, max: 255)
    rng = seed ? Random.new(seed) : Random.new
    (0...n).map { |i|
      r, g, b = 0
      loop {
        r = rng.rand(255)
        g = rng.rand(255)
        b = rng.rand(255)

        # ensure that the random color falls within a range of brightness
        grayness = (0.299 * r + 0.587 * g + 0.114 * b).round
        break if grayness >= min && grayness <= max
      }
      "#%02x%02x%02x" % [r, g, b]
    }
  end

  def distinct_colors(n)
    distinct_colors_random_min_light(n,
                                     seed: @data.values.max * @data.values.size,
                                     min: 150,
                                     max: 200)
  end

  def generate_bar(value)
    scaled_bar_width = scale_bar_width(value)
    bar = @options[:block] * scaled_bar_width
    bar += @options[:block_unfilled] * (@options[:width] - scaled_bar_width) if @options[:block_unfilled]
    bar = "#{color_block(@colors[value])}#{bar}\e[0m" unless @options[:foreground]
    bar = "\e[38;5;#{@options[:foreground]}m#{bar}\e[0m" if @options[:foreground]
    bar = "\e[48;5;#{@options[:background]}m#{bar}\e[0m" if @options[:background]
    bar
  end

  def output_histogram
    cumulated_value = 0

    if @options[:cumulative]
    else
      randomized_values = @data.values.uniq.shuffle(random: Random.new(@data.values.max))
    end
    randomized_values = @data.values.uniq
    colors ||= distinct_colors(randomized_values.size)
    @colors = Hash.new { |hash, key| hash[key] = colors[randomized_values.index(key)] }

    @data.keys.sort.each { |key|
      value = @data[key]
      value += cumulated_value if @options[:cumulative]

      gray = grayness([255, (value.to_f / @data.values.max * 255 + 10).to_i].min)
      reset = "\e[0m"

      @colors[value] = @colors[@data[key]]
      percent = value.to_f / @sum_values * 100
      percent_formatted = "(#{ "%#.1f%%" % percent})".rjust(7)
      percent_formatted.insert(percent_formatted.index('(') + 1, gray)
      percent_formatted.insert(percent_formatted.index(')'), reset)

      bar = generate_bar(value)

      puts ["#{ "%#{@max_width_key}d" % key}",
        "#{gray}#{ "%#{@max_width_value}d" % value }#{reset}",
        "#{percent_formatted}",
        "#{bar}"].join(' ')

      cumulated_value = value if @options[:cumulative]
    }
  end

  def output_stats
    values = @data.values

    puts
    puts "Min/Max: [#{values.min}, #{values.max}]"
    puts "Median: #{TallyMean.median(@data)}"
    puts "Mode: #{TallyMean.mode(@data)}"

    puts "Mean: #{TallyMean.mean(@data)}"
    puts "Geometric mean: #{TallyMean.geometric_mean(@data)}"
    puts "Harmonic mean: #{TallyMean.harmonic_mean(@data)}"

    percentiles = [0.05, 0.25, 0.50, 0.75, 0.95]
    p = percentiles.map { TallyMean.percentile(@data, _1) }
    puts "Percentiles #{percentiles.inspect}: #{p.inspect}"

    puts
  end

  def output
    # TODO log
    # TODO check if value bigger than terminal width

    set_variables
    fill_empty_slots
    output_stats
    output_histogram
    output_summary
  end

  def scale_bar_width(width)
    return width if @options[:width].nil?

    width * @options[:width] / @max_value
  end

  def initialize(io)
    parse_options
    @data = read_data(io)
  end
end

Histogram.new(ARGF).output
