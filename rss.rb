#!/usr/bin/env ruby
require 'optparse'
require 'rss'
require 'open-uri'
require 'ostruct'

class RssDownloader

  def self.parse(args)
    options = OpenStruct.new
    options.directory = '~/incoming'
    options.url_params = []

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: example.rb [options]"

      opts.separator ""
      opts.separator "Specific options:"

			opts.on("-d DIRECTORY", "--directory DIRECTORY",  String, "Save files to DIRECTORY, default is ~/incoming") do |dir|
        unless dir[-1] == "/"
          dir += "/"
        end
				options.directory = dir
			end

      opts.on("-u", "--url URL", String, "RSS feed URL") do |url|
				options.url = url
  		end

      opts.on("-a", "--url-params URL_PARAMETERS_LIST", Array, "Comma separated list of additional parameters to add to all feed and item URLS (i.e. session id), no spaces. Example: sessid=1234567,f=2") do |url_add|
        url_add.each do |param|
				  options.url_params << param
        end
  		end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

    end # opt_parser

    opt_parser.parse!(args)

    unless options.url
      system "echo 'Please set a RSS url with -u URL'"
      exit
    end

    options
  end # parse()

  def self.add_params_to_url(url, params)
    url = "#{url}?#{params.first}"
    params[1..-1].each do |param|
      url += "&#{param}"
    end
      url
  end

  def self.download_rss(options)
		open(self.add_params_to_url(options.url, options.url_params)) do |rss|
			feed = RSS::Parser.parse(rss)
			puts "Saving #{feed.channel.title} to #{options.directory}"
			feed.items.each do |item|
        open(options.directory + item.link.split('/').last, 'wb') do |save_file|
        params = Array.new(options.url_params)
        item.link.split('?').last.split('&').each do |param|
          params << param
        end
        item_link = self.add_params_to_url(item.link.split('?').first, params)
        p item_link
          open(item_link) do |linked_file|
            save_file.print linked_file.read
          end
        end
			end
		end
  end # download_rss()

end # class RssDownloader


options = RssDownloader.parse(ARGV)
RssDownloader.download_rss(options)
