require 'open-uri'
require 'yaml'

class YoutubeDL
  begin
    config = YAML::load_file(File.expand_path(File.join(File.dirname(__FILE__), 'config.yml')))
  rescue
    p 'rescue'
    config = ''
  end
  YOUTUBE_DL_LINK= config["youtube-dl-link"]

  def self.is_installed?
    if system "youtube-dl --version > /dev/null"
      :installed_to_system
    elsif system "#{File.join(File.join(File.dirname(__FILE__), "lib"), "youtube-dl")} --version > /dev/null"
      :installed_to_lib
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
    lib_path =  File.expand_path('lib', File.dirname(__FILE__))
    unless File.directory?(lib_path)
      Dir.mkdir(lib_path)
    end

    open(YOUTUBE_DL_LINK) do |linked_file|
      open(lib_path + '/youtube-dl', 'wb') do |save_file|
        save_file.print linked_file.read
        save_file.chmod(0750)
      end
    end
  p "Installed youtube-dl version is: #{`#{lib_path+'/youtube-dl'} --version`.chomp}"
  end
end

YoutubeDL.is_installed?
