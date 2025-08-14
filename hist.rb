#!/usr/bin/env -S ruby -W2 -w

require 'optparse'
require 'io/console'
_, $width = IO.console.winsize

class Histogram
  VERSION = '0.1'

  def parse_options
    @options = {}
    OptionParser.new do |parser|
      parser.separator 'Output a histogram of input data'
      parser.separator ''
      parser.separator 'Options:'
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
    bar = '#' * scale_bar_width(@max_value)
    percent = '(100.0%)'
    puts "#{' ' * @max_width_key} #{ "%#{@max_width_value}d" % @sum_values} #{percent} #{bar}"
  end

  def output
    fill_empty_slots

    # TODO log
    # TODO check if value bigger than terminal width

    @max_width_key = @data.keys.max_by { |k| k.to_s.size }.to_s.size
    @max_width_value = @data.values.max_by { _1.to_s.size }.to_s.size
    @max_value = @data.values.max
    @sum_values = @data.values.sum

    if @options[:cumulative]
      @max_value = @sum_values
      @max_width_value = @max_value.to_s.size
    end

    # output histogram
    cumulated_value = 0
    @data.keys.sort.each { |key|
      value = @data[key]
      value += cumulated_value if @options[:cumulative]
      percent = value.to_f / @sum_values * 100
      percent_formatted = "(#{ "%#.1f%%" % percent})"
      bar = '#' * scale_bar_width(value)
      puts "#{ "%#{@max_width_key}d" % key} #{ "%#{@max_width_value}d" % value } #{percent_formatted.rjust(8)} #{bar}"

      cumulated_value = value if @options[:cumulative]
    }

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
