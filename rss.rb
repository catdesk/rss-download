#!/usr/bin/env ruby
require 'optparse'
require 'rss'
require 'open-uri'
require 'ostruct'
require 'sqlite3'

class RssDownloader

  def self.parse(args)
    options = OpenStruct.new
    options.directory = '~/incoming'

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: example.rb [options]"

      opts.separator ""
      opts.separator "Specific options:"

			opts.on("-d DIRECTORY", "--directory DIRECTORY",  String, "Save files to DIRECTORY, default is ~/incoming") do |dir|
				options.directory = dir
			end

      opts.on("-u URL", "--url URL", String, "RSS feed URL") do |url|
				options.url = url
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

  def self.download_rss(options)
		open(options.url) do |rss|
			feed = RSS::Parser.parse(rss)
			puts "Saving #{feed.channel.title} to #{options.directory}"
			feed.items.each do |item|
				system "wget -P #{options.directory} -N #{item.link}"
			end
		end
  end # download_rss()

  def self.save_feed_to_db()

    feed_database = SQLite3::Database.new( "feed.database" )

    # first check if sample_table
    database.execute( "create table sample_table (id INTEGER PRIMARY KEY, sample_text TEXT, sample_number NUMERIC);" )

    database.execute( "insert into sample_table (sample_text,sample_number) values ('Sample Text1', 123)")
    database.execute( "insert into sample_table (sample_text,sample_number) values ('Sample Text2', 456)")

    rows = database.execute( "select * from sample_table" )

    # Relevant RSS fields
    # feed.channel.last_build_date or lastBuildDate or nil
    # ...title
    # ...image || image.url or nil
    # feed.item.link
    # ...item.title
    # ...item.pub_date or pubDate
    # ...item.dc_identifier.content or nil
    # ...item.dc_date.content or nil
    # item status (downloaded, new, ignored)
    # item downloaded_at

  end # save_to_db()
end # class RssDownloader

options = RssDownloader.parse(ARGV)
RssDownloader.download_rss(options)

