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
      self.save_feed_to_db(feed, options)

			feed.items.each do |item|
				system "wget -P #{options.directory} -N #{item.link}"
			end
		end
  end # download_rss()

  def self.save_feed_to_db(feed, options)

    database = SQLite3::Database.open( "feed.database" )

    begin
      database.execute( "insert into feeds (channel_title, last_build_date, last_checked_at) values (#{feed.channel.title}, #{options.url}, #{options.directory}, #{feed.channel.last_build_date}, #{Time.now})")
    rescue SQLite3::SQLException => e
      if e.message.include?("no such table")
        database.execute( "create table feeds (id INTEGER PRIMARY KEY, channel_title TEXT, feed_url TEXT, feed_directory TEXT, last_build_date INTEGER, last_checked_at INTEGER);" )
        database.execute( "insert into feeds (channel_title, last_build_date, last_checked_at) values (#{feed.channel.title}, #{options.url}, #{options.directory}, #{feed.channel.last_build_date}, #{Time.now})")
      else
        p e
      end
    rescue Exception => e
      p "BLARHG"
      p e
    end


    p database.execute( "select * from feeds" )

    # Relevant RSS fields
    # feed.channel.last_build_date or lastBuildDate or nil
    # ...title
    # ...image || image.url or nil
    #
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

