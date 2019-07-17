#! /usr/bin/env ruby

# frozen_string_literal: true

require_relative './lib/exporter'
require_relative './lib/repository_exporter'

if ARGV.first == '--private'
  UserDefaultsRepositoryExporter.new('~/Documents/Backups/preferences').export
else
  UserDefaultsExporter.new(output: './exports', exclusions: './exclusions.yaml').export
end
