require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/integration_helper')

describe "Redis-Bank actually talking to a redis client" do
  let(:client) { Redis.new :port => 9736}
  subject { Money::Bank::RedisBank.new(client) }

  describe "persistence" do
    it "stores exchange rates" do
      subject.set_rate("USD", "AUD", 1.23)
      subject.set_rate("USD", "CAD", 2.34)
      subject.get_rate("USD", "AUD").should == "1.23"
    end
    it "has a list of stored exchange rates" do
      subject.rates.should == {"usd_to_aud" => "1.23", "usd_to_cad" => "2.34"}
    end
    it "converts currencies" do
      Money.default_bank = subject
      Money.new(112_358_13, "USD").exchange_to("CAD").cents.should == 26291802
    end
  end
end
