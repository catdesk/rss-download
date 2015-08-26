#!/usr/bin/env ruby
require 'optparse'
require 'rss'
require 'open-uri'
require 'ostruct'
require 'yaml'
require_relative 'rss-downloader'
require_relative 'youtube-dl-py'
require_relative 'processor'

options = Processor.parse(ARGV)

YoutubeDL.is_installed?
Processor.process_rss(options)
