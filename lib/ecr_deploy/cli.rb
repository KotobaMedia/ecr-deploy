class EcrDeploy::CLI
  def self.run!(opts)
    config = EcrDeploy::Config.new(opts.config_file)
    task = EcrDeploy::Task.new(config, opts.environment_name)

    task.deploy!(opts.image_tag)
    task.wait_until_stable

    puts "Deploy finished."
  end
end
