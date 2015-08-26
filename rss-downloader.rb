class RssDownloader
  def self.config
    begin
      YAML::load_file(File.expand_path(File.join(File.dirname(__FILE__), 'config.yml')))
    rescue
      p 'No config file detected'
      ''
    end
  end
end
