CfhighlanderTemplate do
  Name 'glue-job'
  Description "glue-job - #{component_version}"
  DependsOn 'lib-iam'

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true

    ComponentParam 'EnableSchedules', 'true', allowedValues: ['true', 'false']
  end


end
