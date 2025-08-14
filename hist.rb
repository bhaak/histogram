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
      parser.on('-w', '--width=WIDTH', 'Max width of output bar') { |width| @options[:width] = width.to_i }
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

  def output
    # fill empty slots
    min, max = @data.keys.minmax
    (min..max).to_a.each { |i| @data[i] = 0 if @data[i] == 0 }

    # TODO log
    # TODO check if value bigger than terminal width

    @max_width_key = @data.keys.max_by { |k| k.to_s.size }.to_s.size
    @max_width_value = @data.values.max_by { _1.to_s.size }.to_s.size
    @max_value = @data.values.max
    @sum_values = @data.values.sum

    # output histogram
    @data.keys.sort.each { |key|
      value = @data[key]
      percent = value.to_f / @sum_values * 100
      percent_formatted = "(#{ "%#.1f" % percent})"
      bar = '#' * scale_bar_width(value)
      puts "#{ "%#{@max_width_key}d" % key} #{ "%#{@max_width_value}d" % value } #{percent_formatted.rjust(7)} #{bar}"
    }
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
