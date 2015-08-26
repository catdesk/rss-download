class YoutubeDL < RssDownloader

  @install_type = nil
  @lib_path =  File.expand_path('lib', File.dirname(__FILE__))

  YOUTUBE_DL_LINK = self.config["youtube-dl-link"]

  def self.is_installed?
    if system "youtube-dl --version > /dev/null 2>&1"
      @install_type = :installed_to_system
    elsif system "#{File.join(File.join(File.dirname(__FILE__), "lib"), "youtube-dl")} --version > /dev/null 2>&1"
      @install_type = :installed_to_lib
    else
      self.install_prompt
    end
  end

  def self.install_prompt
    p "No youtube-dl detected"
    p "Select (i) install automatically to #{File.expand_path('lib', File.dirname(__FILE__))} or (e) exit and install manually."
    response = gets.chomp
    if response == "i"
      self.install_to_lib
    elsif response == "e"
      exit
    else
      self.install_prompt
    end
  end

  def self.install_to_lib
    unless File.directory?(@lib_path)
      Dir.mkdir(@lib_path)
    end

    open(YOUTUBE_DL_LINK) do |linked_file|
      open(@lib_path + '/youtube-dl', 'wb') do |save_file|
        save_file.print linked_file.read
        save_file.chmod(0750)
      end
    end
  p "Installed youtube-dl version is: #{`#{@lib_path+'/youtube-dl'} --version`.chomp}"
  end

  def self.download_audio(link, download_directory)
    if @install_type == :installed_to_system
      system "youtube-dl -x #{link} -o '#{download_directory}%(title)s-%(id)s.%(ext)s'"
    elsif @install_type == :installed_to_lib
      system "#{@lib_path+'/youtube-dl'} -x #{link}"
    end
  end
end

YoutubeDL.is_installed?
