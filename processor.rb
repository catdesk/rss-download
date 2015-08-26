class Processor < RssDownloader

  def self.parse(args)
    options = OpenStruct.new
    options.directory = File.expand_path('~/incoming') + '/'
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

      opts.on("-m", "--download-method DOWNLOAD_METHOD", String, "Use \"youtube-dl\" or \"simple\" downloading. Default is simple.") do |dl_method|
        options.download = dl_method
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
    if params.length > 0
      url = "#{url}?#{params.first}"
      params[1..-1].each do |param|
        url += "&#{param}"
      end
    end
    url
  end

  def self.process_rss(options)
		open(self.add_params_to_url(options.url, options.url_params)) do |rss|
			feed = RSS::Parser.parse(rss)
			puts "Saving #{feed.channel.title} to #{options.directory}"
			feed.items.each do |item|
      p item
        params = Array.new(options.url_params)
        item.link.split('?').last.split('&').each do |param|
          params << param
        end
        item_link = self.add_params_to_url(item.link.split('?').first, params)
        if options.download == "youtube-dl"
          YoutubeDL.download_audio(item_link, options.directory)
        else
          open(item_link) do |linked_file|
            if linked_file.meta['content-disposition'] and linked_file.meta['content-disposition'].split("\"").first.include?('file')
              filename = linked_file.meta['content-disposition'].split("\"").last
            else
              filename = item_link.split('/').last.gsub(/[&:]/, '-')
            end
            open(options.directory + filename, 'wb') do |save_file|
              save_file.print linked_file.read
            end
          end
        end
			end
		end
  end # process_rss()

end # class RssDownloader::Processor
