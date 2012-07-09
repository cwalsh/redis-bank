require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/integration_helper')

describe "Redis-Bank actually talking to a redis client" do
  let(:client) { Redis.new :port => 9736}
  let(:bank) { Money::Bank::RedisBank.new(client) }

  describe "persistence" do
    it "stores exchange rates" do
      bank.set_rate("USD", "AUD", 1.23)
      bank.set_rate("USD", "CAD", 2.34)
      bank.get_rate("USD", "AUD").should == "1.23"
    end
    it "has a list of stored exchange rates" do
      bank.rates.should == {"usd_to_aud" => "1.23", "usd_to_cad" => "2.34"}
    end
    it "converts currencies" do
      Money.default_bank = bank
      Money.new(112_358_13, "USD").exchange_to("CAD").cents.should == 26291802
    end
  end
  describe "missing rates fallbacks" do
    before :each do
      client.del "redis_bank_exchange_rates"
      bank.set_fallback(true) { {"gbp_to_aud" => 1.75, "jpy_to_aud" => 0.0123} }
    end
    it "uses the fallback rates callback and sets the new rates" do
      bank.rates.should == {"gbp_to_aud" => 1.75 , "jpy_to_aud" => 0.0123}
      client.hget("redis_bank_exchange_rates", "gbp_to_aud").should == "1.75"
    end
    it "sets single currency rates from the callback" do
      Money.default_bank = bank
      Money.new(1000, "JPY").exchange_to("AUD").should == Money.new(1230, "AUD")
      client.hget("redis_bank_exchange_rates", "jpy_to_aud").should == "0.0123"
    end
  end
end
