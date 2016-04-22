require "yaml"

class EcrDeploy::Config
  def initialize(path)
    @config = YAML.load(IO.read(path))
  end

  def base_config
    @config["base_config"]
  end

  def services(environment)
    @config[environment]["services"] || []
  end

  def run_tasks(environment)
    @config[environment]["run_tasks"] || []
  end

  def register_tasks(environment)
    @config[environment]["register_tasks"] || []
  end

  def environments
    @config.keys.reject { |e| e == "base_config" }
  end
end
