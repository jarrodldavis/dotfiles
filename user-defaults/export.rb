#! /usr/bin/env ruby

# frozen_string_literal: true

require_relative './lib/exporter'

UserDefaultsExporter.new(output: './exports', exclusions: './exclusions.yaml').export
