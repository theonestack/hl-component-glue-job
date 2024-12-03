CloudFormation do

  Condition(:ScheduleEnabled, FnEquals(Ref(:EnableSchedules), 'true'))

  iam_policies = external_parameters.fetch(:iam_policies, {})
  IAM_Role(:GlueServiceRole) {
    AssumeRolePolicyDocument service_assume_role_policy(['glue'])
    ManagedPolicyArns([
      'arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole'
    ])

    unless iam_policies.empty?
      Policies iam_role_policies(iam_policies)
    end
  }

  glue_job_default_args = external_parameters.fetch(:glue_job_default_args, {})
  glue_job_defaults = external_parameters.fetch(:glue_job_defaults, {})
  
  # load job defaults
  default_max_concurrent_runs = glue_job_defaults.fetch('max_concurrent_runs', nil)
  default_max_retries= glue_job_defaults.fetch('max_retries', nil)
  default_allocated_capacity = glue_job_defaults.fetch('allocated_capacity', nil)
  default_maximum_capacity = glue_job_defaults.fetch('maximum_capacity', nil)
  default_glue_version = glue_job_defaults.fetch('glue_version', nil)
  default_pylibs = glue_job_defaults.fetch('pylibs', nil)

  glue_jobs = external_parameters.fetch(:glue_jobs, {})
  glue_jobs.each do |job_name, job|
    description = job.has_key?('description') ? job['description'] : job_name
    job_resource_name = job_name.capitalize.gsub(/[^0-9A-Za-z]/, '')

    default_args = glue_job_default_args.dup
    default_args.merge!(job.fetch("default_args", {}))

    pylibs = job.fetch('pylibs', default_pylibs)
    default_args[:"--extra-py-files"] = pylibs unless pylibs.nil?

    max_retries = job.fetch('max_retries', default_max_retries)
    allocated_capacity = job.fetch('allocated_capacity', default_allocated_capacity)
    maximum_capacity = job.fetch('maximum_capacity', default_maximum_capacity)
    max_concurrent_runs = job.fetch('max_concurrent_runs', default_max_concurrent_runs)
    glue_version = job.fetch('glue_version', default_glue_version)

    Glue_Job(job_resource_name) do
      Name FnSub("${EnvironmentName}-#{job_name}")
      Description FnSub(description)
      Role Ref(:GlueServiceRole)

      unless glue_version.nil?
        GlueVersion glue_version
      end

      unless max_retries.nil?
        MaxRetries max_retries
      end

      unless allocated_capacity.nil?
        MaxCapacity allocated_capacity
      end
      
      unless maximum_capacity.nil?
        MaxCapacity maximum_capacity
      end
      
      unless max_concurrent_runs.nil?
        ExecutionProperty({
          MaxConcurrentRuns: max_concurrent_runs
        })
      end
      
      if job.has_key?('connections')
        Connections({
          Connections: job['connections'].map {|conn| FnSub(conn)}
        })
      end

      DefaultArguments default_args.map {|k,v| [k, FnSub(v)]}.to_h unless default_args.empty?

      if job.has_key?('command')
        Command({
          Name: job['command']['name'],
          ScriptLocation: FnSub(job['command']['script'])
        })
      end
    end

    if job.has_key?('schedule')
      Glue_Trigger("#{job_resource_name}Trigger") do
        Condition :ScheduleEnabled
        Name FnSub("${EnvironmentName}-#{job_name}-trigger")
        Type 'SCHEDULED'
        StartOnCreation true
        Description description
        Schedule job['schedule']
        Actions [{
          JobName: FnSub("${EnvironmentName}-#{job_name}")
        }]
      end
    end
  end


end
