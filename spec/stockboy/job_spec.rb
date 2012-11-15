require 'spec_helper'
require 'stockboy/job'

module Stockboy
  describe Job do
    let(:jobs_path) { RSpec.configuration.fixture_path.join('jobs') }
    let(:provider_stub) { stub(:ftp).as_null_object }
    let(:reader_stub)   { stub(:csv).as_null_object }

    let(:job_template) {
      <<-END.gsub(/^ {6}/,'')
      provider :ftp do
        username 'foo'
        password 'bar'
        host 'ftp.example.com'
      end
      format   :csv
      filter :blank_name do |r|
        false if r.name.blank?
      end
      attributes do
        name from: 'userName'
        email from: 'email'
        updated_at from: 'statusDate', as: [:date]
      end
      END
    }

    before do
      Stockboy.configuration.template_load_paths = [jobs_path]
    end

    its(:filters) { should be_a Hash }

    describe "#define" do
      before do
        File.stub!(:read)
            .with("#{jobs_path}/test_job.rb")
            .and_return job_template
      end

      it "returns an instance of Job" do
        Job.define("test_job").should be_a Job
      end

      it "should read a file from a path" do
        File.should_receive(:read).with("#{jobs_path}/test_job.rb")
        Job.define("test_job")
      end

      it "assigns a registered provider from a symbol" do
        Stockboy::Providers.should_receive(:find)
                           .with(:ftp)
                           .and_return(provider_stub)
        job = Job.define("test_job")
        job.provider.should == provider_stub
      end

      it "assigns a registered reader from a symbol" do
        Stockboy::Readers.should_receive(:find)
                         .with(:csv)
                         .and_return(reader_stub)
        job = Job.define("test_job")
        job.reader.should == reader_stub
      end

      it "assigns attributes from a block" do
        job = Job.define("test_job")
        job.attributes.map(&:to).should == [:name, :email, :updated_at]
      end
    end

    describe "#process" do
      let(:attribute_map) { AttributeMap.new { name } }

      subject(:job) do
        Job.new(provider: stub(:provider, data:"", errors:[]),
                attributes: attribute_map)
      end

      it "records total received record count" do
        job.reader = stub(parse: [{name:"A"},{name:"B"}])

        job.process
        job.total_records.should == 2
      end

      it "partitions records by filter" do
        job.reader = stub(parse: [{"name"=>"A"},{"name"=>"B"}])
        job.filters = {alpha: proc{ |r| r.name =~ /A/ }}

        job.process
        job.records[:alpha].length.should == 1
      end

      it "keeps unfiltered_records" do
        job.reader = stub(parse: [{"name"=>"A"}])
        job.filters = {zeta: proc{ |r| r.name =~ /Z/ }}

        job.process
        job.unfiltered_records.length.should == 1
      end

      it "keeps all_records" do
        job.reader = stub(parse: [{"name"=>"A"},{"name"=>"Z"}])
        job.filters = {alpha: proc{ |r| r.name =~ /A/ }}

        job.process
        job.all_records.length.should == 2
      end
    end

  end
end
