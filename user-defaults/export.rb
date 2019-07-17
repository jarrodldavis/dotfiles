#! /usr/bin/env ruby

# frozen_string_literal: true

require 'time'
require_relative './lib/exporter'

if ARGV.first == '--private'
  time = Time.now.getutc.strftime('%Y%m%dT%H%MZ')
  UserDefaultsExporter.new(output: "~/Documents/user-defaults/#{time}").export
else
  UserDefaultsExporter.new(output: './exports', exclusions: './exclusions.yaml').export
end
