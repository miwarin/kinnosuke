# coding: utf-8

module MSKinnosuke
  class Config
    def initialize(config_path)
      @config = eval(File.open(config_path).read)
    end

    def method_missing(name)
      return @config[name.to_sym] if @config.has_key?(name.to_sym)
      super.method_missing(name)
    end
  end
end
