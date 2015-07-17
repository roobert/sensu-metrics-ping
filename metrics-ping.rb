#!/usr/bin/env ruby
#! /usr/bin/env ruby
#
# metrics-ping
#
# DESCRIPTION:
#  This plugin pings a host and outputs ping statistics
#
# OUTPUT:
#  <scheme>.packets_transmitted 5 1437137076
#  <scheme>.packets_received 5 1437137076
#  <scheme>.packet_loss 0 1437137076
#  <scheme>.time 3996 1437137076
#  <scheme>.min 0.016 1437137076
#  <scheme>.max 0.017 1437137076
#  <scheme>.avg 0.019 1437137076
#  <scheme>.mdev 0.004 1437137076
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: open3
#
# USAGE:
#   ./metric-ping --host <host> --count <count> \
#                 --timeout <timeout> --scheme <scheme>
#
# NOTES:
#
# LICENSE:
#   Copyright 2015 Rob Wilson <roobert@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'socket'
require 'open3'

class PingMetrics < Sensu::Plugin::Check::CLI
  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-s SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.ping"

  option :host,
         description: 'Host to ping',
         short: '-h HOST',
         long: '--host HOST',
         default: 'localhost'

  option :count,
         description: 'Ping count',
         short: '-c COUNT',
         long: '--count COUNT',
         default: 5

  option :timeout,
         description: 'Timeout',
         short: '-t TIMEOUT',
         long: '--timeout TIMEOUT',
         default: 5

  OVERVIEW_METRICS = [ :packets_transmitted, :packets_received, :packet_loss, :time ]
  STATISTIC_METRICS = [ :min, :max, :avg, :mdev ]
  FLOAT = '(\d+\.\d+)'

  def overview
    @ping.split("\n")[-2].scan(/^(\d+) packets transmitted, (\d+) received, (\d+)% packet loss, time (\d+)ms/)[0]
  end

  def statistics
    @ping.split("\n")[-1].scan(/^rtt min\/avg\/max\/mdev = #{FLOAT}\/#{FLOAT}\/#{FLOAT}\/#{FLOAT} ms/)[0]
  end

  def results
    Hash[OVERVIEW_METRICS.zip(overview)].merge Hash[STATISTIC_METRICS.zip(statistics)]
  end

  def timestamp
    @timestamp ||= Time.now.to_i
  end

  def output
    results.each { |metric, value| puts "#{config[:scheme]}.#{metric} #{value} #{timestamp}" }
  end

  def ping
    @ping, status = Open3.capture2e("ping -W#{config[:timeout]} -c#{config[:count]} #{config[:host]}")

    critical "ping error: (#{status}): #{@ping}" if status != 0
  end

  def run
    ping
    output
    exit 0
  end
end
