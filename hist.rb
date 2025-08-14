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

    key_width = @data.keys.max_by { |k| k.to_s.size }.to_s.size

    # output histogram
    @data.keys.sort.each { |key|
      value = @data[key]
      puts "#{ "%#{key_width}d" % key} #{'#' * value}"
    }
  end

  def initialize(io)
    parse_options
    @data = read_data(io)
  end
end

Histogram.new(ARGF).output
