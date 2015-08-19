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
#				system "wget -P #{options.directory} -N #{item.link}"
			end
		end
  end # download_rss()

  def self.save_feed_to_db(feed, options)

    database = SQLite3::Database.open( "feed.database" )

    begin
      self.insert_feed(database, feed, options)
    rescue SQLite3::SQLException => e
      if e.message.include?("no such table")
        p "NO SUCH TABLE, CREATING"
        database.execute( "CREATE table feeds (id INTEGER PRIMARY KEY, channel_title TEXT, feed_url TEXT, feed_directory TEXT, last_build_date INTEGER, last_checked_at INTEGER);" )
        self.insert_feed(database, feed, options)
      else
        p "OTHER SQL POOP"
        p e
      end
    rescue Exception => e
      p "BLARHG"
      p e
    end


    p database.execute( "SELECT * FROM feeds" )

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

  def self.insert_feed(database, feed, options)
    extant_feed = database.execute( "SELECT id FROM feeds WHERE feed_url='#{options.url}'" )
    p extant_feed
    if extant_feed.count == 0
      database.execute( "INSERT INTO feeds (channel_title, feed_url, feed_directory, last_build_date, last_checked_at) VALUES ('#{feed.channel.title}', '#{options.url}', '#{options.directory}', #{(feed.channel.respond_to?('last_build_date') ? feed.channel.last_build_date.to_i : feed.channel.lastBuildDate.to_i)}, #{Time.now.to_i})")
    else
      database.execute( "UPDATE feeds SET last_build_date='#{(feed.channel.respond_to?('last_build_date') ? feed.channel.last_build_date.to_i : feed.channel.lastBuildDate.to_i)}', last_checked_at='#{Time.now.to_i}' WHERE id=#{extant_feed[0][0]}" )
    end
  end # insert_feed()

end # class RssDownloader

options = RssDownloader.parse(ARGV)
RssDownloader.download_rss(options)

