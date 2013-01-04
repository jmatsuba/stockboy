require 'spec_helper'
require 'stockboy/providers/soap'

module Stockboy
  describe Providers::SOAP do
    before(:all) { savon.mock!   }
    after(:all)  { savon.unmock! }
    subject(:soap) { Stockboy::Providers::SOAP.new }

    it "should assign parameters" do
      soap.wsdl      = "http://api.example.com/?wsdl"
      soap.request   = :get_user
      soap.namespace = "http://api.example.com/"
      soap.message   = {user: 'u', pass: 'p'}
      soap.headers   = {key: 'k'}

      soap.wsdl.should      == "http://api.example.com/?wsdl"
      soap.request.should   == :get_user
      soap.namespace.should == "http://api.example.com/"
      soap.message.should   == {user: 'u', pass: 'p'}
      soap.headers.should   == {key: 'k'}
    end

    describe ".new" do
      its(:errors) { should be_empty }

      it "accepts block initialization" do
        soap = Providers::SOAP.new do |p|
          p.request   = :get_user
          p.endpoint  = "http://api.example.com/v1"
          p.namespace = "http://api.example.com/namespace"
          p.wsdl      = "http://api.example.com/?wsdl"
          p.message   = {user: 'u', pass: 'p'}
          p.headers   = {key: 'k'}
        end

        soap.request.should   == :get_user
        soap.endpoint.should  == "http://api.example.com/v1"
        soap.wsdl.should      == "http://api.example.com/?wsdl"
        soap.namespace.should == "http://api.example.com/namespace"
        soap.message.should   == {user: 'u', pass: 'p'}
        soap.headers.should   == {key: 'k'}
      end
    end

    describe "validation" do
      context "with a WSDL document" do
        before { soap.wsdl = "http://api.example.com/?wsdl" }
        it     { should be_valid }
      end

      context "without a WSDL document" do
        it "has error for blank endpoint & WSDL namespace" do
          soap.valid?
          soap.errors.keys.should include(:endpoint)
        end
      end
    end

    describe "#data" do
      let(:xml_success_fixture) {
        File.read(RSpec.configuration.fixture_path.join "soap/get_list/success.xml")
      }

      subject(:soap) do
        Providers::SOAP.new do |s|
          s.endpoint = "http://api.example.com/v1"
          s.namespace = ''
          s.request = :get_list
          s.message = {username: "user", password: "pass"}
        end
      end

      it "returns hash data on success" do
        savon.expects(:get_list)
             .with(message: {username: 'user', password: 'pass'})
             .returns(xml_success_fixture)
        response = soap.data

        response.should be_a Hash
      end
    end
  end
end
