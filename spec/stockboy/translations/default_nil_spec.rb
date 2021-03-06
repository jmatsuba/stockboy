require 'spec_helper'
require 'stockboy/translations/default_nil'

module Stockboy
  describe Translations::DefaultNil do

    subject { described_class.new(:email) }

    describe "#call" do
      it "returns nil for empty string" do
        result = subject.call email: ""
        expect(result).to eq nil
      end

      it "returns nil for nil" do
        result = subject.call email: nil
        expect(result).to eq nil
      end

      it "returns original value if present" do
        result = subject.call email: "a@example.com"
        expect(result).to eq "a@example.com"
      end

      it "returns original value when zero" do
        result = subject.call email: 0
        expect(result).to eq 0
      end
    end

  end
end
