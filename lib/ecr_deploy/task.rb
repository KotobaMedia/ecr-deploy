require 'json'

class EcrDeploy::Task
  def initialize(config, environment)
    fail ArgumentError, "#{environment} does not exist in the configuration." \
      if !config.environments.include?(environment)

    @ecs = Aws::ECS::Client.new
    s3 = Aws::S3::Resource.new

    @cluster_name = config.base_config["cluster"]

    @service_names = config.services(environment)
    @run_task_names = config.run_tasks(environment)
    @register_task_names = config.register_tasks(environment)

    @bucket = s3.bucket(config.base_config["template_bucket"])
    @bucket_prefix = config.base_config["template_bucket_prefix"] || ""

    @environment = environment
    @env_vars = @bucket.
      object(build_path("#{environment}-env.json")).get.body.string
  end

  def deploy!(image_tag_name)
    task_def_names = (@service_names + @run_task_names + @register_task_names).uniq
    task_def_arns = task_def_names.map { |name| register_task_definition(name, image_tag_name) }
    task_def = Hash[task_def_names.zip(task_def_arns)]

    @service_names.each do |name|
      service_name = "#{@environment}-#{name}"
      $stderr.puts "==> Updating service \"#{service_name}\""
      @ecs.update_service(
        cluster: @cluster_name,
        service: service_name,
        task_definition: task_def[name])
    end

    @run_task_names.each do |name|
      $stderr.puts "==> Running task \"#{name}\" in \"#{@environment}\""
      @ecs.run_task(
        cluster: @cluster_name,
        task_definition: task_def[name],
        count: 1)
    end
  end

  def wait_until_stable(wait_time = 600)
    services = @service_names.map { |name| "#{@environment}-#{name}" }
    $stderr.puts "==> Waiting for #{services.join ", "} to stabilize..."
    started_at = Time.now
    @ecs.wait_until(:services_stable, cluster: @cluster, services: services) do |w|
      w.max_attempts = nil

      w.before_wait do |attempts, response|
        throw :failure if Time.now - started_at > wait_time
      end
    end
  rescue Aws::Waiters::Errors::WaiterFailed => e
    $stderr.puts "!!> An error occurred while waiting for services to stabilize. #{e}"
  end

  def register_task_definition(name, image_tag_name)
    template = @bucket.object(build_path("#{@environment}-#{name}.json")).
      get.body.string
    template.gsub!("[CURRENT_IMAGE_TAG]", image_tag_name)
    template.gsub!("[ENVIRONMENT]", @env_vars)

    template_obj = JSON.parse(template, symbolize_names: true)
    task = @ecs.register_task_definition(template_obj)

    task.task_definition.task_definition_arn
  end

  private

  def build_path(path)
    @bucket_prefix + path
  end
end
