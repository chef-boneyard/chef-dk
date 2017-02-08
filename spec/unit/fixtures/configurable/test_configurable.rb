require "unit/fixtures/configurable/test_config_loader"

class TestConfigurable
  include ChefDK::Configurable

  # don't use the workstation config loader
  def config_loader
    @config_loader ||= TestConfigLoader.new
  end
end
