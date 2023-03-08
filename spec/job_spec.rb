require 'yaml'

describe 'compiled component glue-job' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/job.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/job/glue-job.compiled.yaml") }
  
  context "Resource" do

    
    context "GlueServiceRole" do
      let(:resource) { template["Resources"]["GlueServiceRole"] }

      it "is of type AWS::IAM::Role" do
          expect(resource["Type"]).to eq("AWS::IAM::Role")
      end
      
      it "to have property AssumeRolePolicyDocument" do
          expect(resource["Properties"]["AssumeRolePolicyDocument"]).to eq({"Version"=>"2012-10-17", "Statement"=>[{"Effect"=>"Allow", "Principal"=>{"Service"=>"glue.amazonaws.com"}, "Action"=>"sts:AssumeRole"}]})
      end
      
      it "to have property ManagedPolicyArns" do
          expect(resource["Properties"]["ManagedPolicyArns"]).to eq(["arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"])
      end
      
    end
    
    context "Jobname" do
      let(:resource) { template["Resources"]["Jobname"] }

      it "is of type AWS::Glue::Job" do
          expect(resource["Type"]).to eq("AWS::Glue::Job")
      end
      
      it "to have property Name" do
          expect(resource["Properties"]["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}-job_name"})
      end
      
      it "to have property Description" do
          expect(resource["Properties"]["Description"]).to eq({"Fn::Sub"=>"example job"})
      end
      
      it "to have property Role" do
          expect(resource["Properties"]["Role"]).to eq({"Ref"=>"GlueServiceRole"})
      end
      
      it "to have property MaxRetries" do
          expect(resource["Properties"]["MaxRetries"]).to eq(0)
      end
      
      it "to have property AllocatedCapacity" do
          expect(resource["Properties"]["AllocatedCapacity"]).to eq(2)
      end
      
      it "to have property ExecutionProperty" do
          expect(resource["Properties"]["ExecutionProperty"]).to eq({"MaxConcurrentRuns"=>1})
      end
      
      it "to have property Connections" do
          expect(resource["Properties"]["Connections"]).to eq({"Connections"=>[{"Fn::Sub"=>"GlueConnection"}]})
      end
      
      it "to have property DefaultArguments" do
          expect(resource["Properties"]["DefaultArguments"]).to eq({"--extra-py-files"=>{"Fn::Sub"=>"s3://bucket-name/pylibs.zip"}})
      end
      
      it "to have property Command" do
          expect(resource["Properties"]["Command"]).to eq({"Name"=>"main", "ScriptLocation"=>{"Fn::Sub"=>"s3://bucket-name/scripts/main.py"}})
      end
      
    end
    
    context "JobnameTrigger" do
      let(:resource) { template["Resources"]["JobnameTrigger"] }

      it "is of type AWS::Glue::Trigger" do
          expect(resource["Type"]).to eq("AWS::Glue::Trigger")
      end
      
      it "to have property Name" do
          expect(resource["Properties"]["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}-job_name-trigger"})
      end
      
      it "to have property Type" do
          expect(resource["Properties"]["Type"]).to eq("SCHEDULED")
      end
      
      it "to have property Description" do
          expect(resource["Properties"]["Description"]).to eq("example job")
      end
      
      it "to have property Schedule" do
          expect(resource["Properties"]["Schedule"]).to eq("cron(01 19 * * ? *)")
      end
      
      it "to have property Actions" do
          expect(resource["Properties"]["Actions"]).to eq([{"JobName"=>{"Fn::Sub"=>"${EnvironmentName}-job_name"}}])
      end
      
    end
    
  end

end