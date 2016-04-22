require "ostruct"

class EcrDeploy::Optparse
  def self.parse(args)
    options = OpenStruct.new

    options.config_file = args[0] || show_usage
    options.environment_name = args[1] || show_usage
    options.image_tag = args[2] || show_usage

    options
  end

  private

  def self.show_usage
    puts "Usage: ecr-deploy path_to_configuration.yml ENVIRONMENT_NAME IMAGE_TAG"
    exit 127
  end
end
