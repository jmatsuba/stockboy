require 'spec_helper'
require 'stockboy/translations/integer'

module Stockboy
  describe Translations::Integer do

    subject { described_class.new(:id) }

    describe "#call" do
      it "returns nil for an empty string" do
        subject.call(id: "").should be_nil
      end

      it "returns an integer" do
        result = subject.call(id: "42")
        result.should == 42
      end
    end

  end
end
