require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Money::Bank::RedisBank do

  let(:client) do
    Hash.new.tap do |fake_redis_client|
      def fake_redis_client.hset(k,f,v)
        self[f]=v
      end
      def fake_redis_client.hget(k,f)
        self[f]
      end
      def fake_redis_client.hgetall(k)
        self
      end
      def fake_redis_client.mapped_hmset(k,hsh)
        self.clear
        hsh.each {|k,v| self[k]=v}
      end
    end
  end
  subject { Money::Bank::RedisBank.new(client) }

  describe "#initialize" do
    context "without &block" do
      let(:bank) {
        Money::Bank::RedisBank.new(client).tap do |bank|
          bank.add_rate('USD', 'EUR', 1.33)
        end
      }

      describe "#exchange_with" do
        it "accepts str" do
          expect { bank.exchange_with(Money.new(100, 'USD'), 'EUR') }.to_not raise_exception
        end

        it "accepts currency" do
          expect { bank.exchange_with(Money.new(100, 'USD'), Money::Currency.wrap('EUR')) }.to_not raise_exception
        end

        it "exchanges one currency to another" do
          bank.exchange_with(Money.new(100, 'USD'), 'EUR').should == Money.new(133, 'EUR')
        end

        it "truncates extra digits" do
          bank.exchange_with(Money.new(10, 'USD'), 'EUR').should == Money.new(13, 'EUR')
        end

        it "raises an UnknownCurrency exception when an unknown currency is requested" do
          expect { bank.exchange_with(Money.new(100, 'USD'), 'BBB') }.to raise_exception(Money::Currency::UnknownCurrency)
        end

        it "raises an UnknownRate exception when an unknown rate is requested" do
          expect { bank.exchange_with(Money.new(100, 'USD'), 'JPY') }.to raise_exception(Money::Bank::UnknownRate)
        end

        it "accepts a custom rounding method" do
          proc = Proc.new { |n| n.ceil }
          bank.exchange_with(Money.new(10, 'USD'), 'EUR', &proc).should == Money.new(14, 'EUR')
        end
      end
    end

    context "with a pre-configured rounding method" do
      let(:bank) {
        rounding_method = Proc.new { |n| n.ceil }
        Money::Bank::RedisBank.new(client,&rounding_method).tap do |bank|
          bank.add_rate('USD', 'EUR', 1.33)
        end
      }

      describe "#exchange_with" do
        it "uses the stored rounding method" do
          bank.exchange_with(Money.new(10, 'USD'), 'EUR').should == Money.new(14, 'EUR')
        end

        it "accepts a custom rounding method" do
          proc = Proc.new { |n| n.ceil + 1 }
          bank.exchange_with(Money.new(10, 'USD'), 'EUR', &proc).should == Money.new(15, 'EUR')
        end
      end
    end
  end

  describe "#add_rate" do
    it "adds rates correctly" do
      subject.add_rate("USD", "EUR", 0.788332676)
      subject.add_rate("EUR", "YEN", 122.631477)

      subject.get_rate('USD', 'EUR').should == 0.788332676
      subject.get_rate('EUR', 'JPY').should == 122.631477
    end

    it "treats currency names case-insensitively" do
      subject.add_rate("usd", "eur", 1)
      subject.get_rate('USD', 'EUR').should == 1
    end
  end

  describe "#set_rate" do
    it "sets a rate" do
      subject.set_rate('USD', 'EUR', 1.25)
      subject.get_rate('USD', 'EUR').should == 1.25
    end

    it "raises an UnknownCurrency exception when an unknown currency is passed" do
      expect { subject.set_rate('AAA', 'BBB', 1.25) }.to raise_exception(Money::Currency::UnknownCurrency)
    end
  end

  describe "#get_rate" do
    it "returns a rate" do
      subject.set_rate('USD', 'EUR', 1.25)
      subject.get_rate('USD', 'EUR').should == 1.25
    end

    context "has same currency for source and detination" do
      it "returns 1.0" do
        subject.get_rate('AUD', 'AUD').should == 1.0
      end

      it "is case-insensitive" do
        subject.get_rate('aud', 'AUD').should == 1.0
      end

      it "ignores leading and trailing spaces" do
        subject.get_rate(' AUD', 'AUD ').should == 1.0
      end
    end

    it "raises an UnknownCurrency exception when an unknown currency is passed" do
      expect { subject.get_rate('AAA', 'BBB') }.to raise_exception(Money::Currency::UnknownCurrency)
    end
  end

  describe "#rate_key_for" do
    it "accepts str/str" do
      expect { subject.send(:rate_key_for, 'USD', 'EUR')}.to_not raise_exception
    end

    it "accepts currency/str" do
      expect { subject.send(:rate_key_for, Money::Currency.wrap('USD'), 'EUR')}.to_not raise_exception
    end

    it "accepts str/currency" do
      expect { subject.send(:rate_key_for, 'USD', Money::Currency.wrap('EUR'))}.to_not raise_exception
    end

    it "accepts currency/currency" do
      expect { subject.send(:rate_key_for, Money::Currency.wrap('USD'), Money::Currency.wrap('EUR'))}.to_not raise_exception
    end

    it "returns a hashkey based on the passed arguments" do
      subject.send(:rate_key_for, 'USD', 'EUR').should == 'usd_to_eur'
      subject.send(:rate_key_for, Money::Currency.wrap('USD'), 'EUR').should == 'usd_to_eur'
      subject.send(:rate_key_for, 'USD', Money::Currency.wrap('EUR')).should == 'usd_to_eur'
      subject.send(:rate_key_for, Money::Currency.wrap('USD'), Money::Currency.wrap('EUR')).should == 'usd_to_eur'
    end

    it "raises a Money::Currency::UnknownCurrency exception when an unknown currency is passed" do
      expect { subject.send(:rate_key_for, 'AAA', 'BBB') }.to raise_exception(Money::Currency::UnknownCurrency)
    end
  end

  describe "#rates" do
    it "gets all the exchange rates" do
      subject.add_rate("USD", "EUR", 0.788332676)
      subject.add_rate("EUR", "YEN", 122.631477)
      subject.rates.should == {"usd_to_eur" => 0.788332676, "eur_to_jpy" => 122.631477 }
    end
  end

  describe "fallbacks" do
    let(:forgetful_client) { client }
    let(:bad_bank) { Money::Bank::RedisBank.new(forgetful_client) }

    context "when all the rates are missing" do
      before :each do
        bad_bank.rates.should == {}
        bad_bank.set_fallback(true) { {"gbp_to_aud" => 1.75 } }
      end
      it "gets the exchange rates from the fallback" do
        bad_bank.rates.should == {"gbp_to_aud" => 1.75 }
      end
      it "sets the exchange rates from the fallback" do
        forgetful_client.should_receive(:mapped_hmset)
        bad_bank.rates.should == {"gbp_to_aud" => 1.75 }
      end
    end
    context "when some of the rates are missing" do
      before :each do
        forgetful_client.clear
        bad_bank.set_fallback(true) { {"gbp_to_aud" => 1.75 } }
        Money.default_bank = bad_bank
      end
      it "gets the missing exchange rate from the fallback" do
        Money.new(1000, "GBP").exchange_to("AUD").should == Money.new(1750, "AUD")
      end
      context "with writethrough" do
        it "sets the missing exchange rate from the fallback" do
          forgetful_client.should_receive(:mapped_hmset)
          Money.new(1000, "GBP").exchange_to("AUD").should == Money.new(1750, "AUD")
        end
      end
      context "without writethrough" do
        it "sets the missing exchange rate from the fallback" do
          bad_bank.set_fallback(false) { {"gbp_to_aud" => 1.75 } }
          forgetful_client.should_not_receive(:mapped_hmset)
          Money.new(1000, "GBP").exchange_to("AUD").should == Money.new(1750, "AUD")
        end
      end
    end
  end
  describe "error handling" do
    let(:unstable_client) { client }
    let(:bad_bank) { Money::Bank::RedisBank.new(unstable_client) }
    context "with fallbacks" do
      before :each do
        bad_bank.set_fallback(false) { {"jpy_to_aud" => 0.00123} }
        Money.default_bank = bad_bank
      end
      it "falls back to the fallback proc when exchanging currencies" do
        unstable_client.should_receive(:hget).and_raise Redis::CannotConnectError
        Money.new(1000, "JPY").exchange_to("AUD").should == Money.new(123, "AUD")
      end
      it "falls back to the fallback proc when requesting rates" do
        unstable_client.should_receive(:hgetall).and_raise Redis::CannotConnectError
        bad_bank.rates.should == {"jpy_to_aud" => 0.00123}
      end
    end
    context "without fallbacks" do
      it "fails as usual when trying to exchange currencies" do
        Money.default_bank = bad_bank
        unstable_client.should_receive(:hget).and_raise Redis::CannotConnectError
        expect { Money.new(1000, "JPY").exchange_to "AUD" }.to raise_error Redis::CannotConnectError
      end
      it "fails as usual when getting rates" do
        unstable_client.should_receive(:hgetall).and_raise Redis::CannotConnectError
        expect { bad_bank.rates }.to raise_error Redis::CannotConnectError
      end
    end
  end
end
