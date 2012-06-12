require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Money::Bank::RedisBank do

  subject { Money::Bank::RedisBank.new(Hash.new) }

  describe "#initialize" do
    context "without &block" do
      let(:bank) {
        Money::Bank::RedisBank.new(Hash.new).tap do |bank|
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
        Money::Bank::RedisBank.new(Hash.new,&rounding_method).tap do |bank|
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
      subject.send(:rate_key_for, 'USD', 'EUR').should == 'USD_TO_EUR'
      subject.send(:rate_key_for, Money::Currency.wrap('USD'), 'EUR').should == 'USD_TO_EUR'
      subject.send(:rate_key_for, 'USD', Money::Currency.wrap('EUR')).should == 'USD_TO_EUR'
      subject.send(:rate_key_for, Money::Currency.wrap('USD'), Money::Currency.wrap('EUR')).should == 'USD_TO_EUR'
    end

    it "raises a Money::Currency::UnknownCurrency exception when an unknown currency is passed" do
      expect { subject.send(:rate_key_for, 'AAA', 'BBB')}.should raise_exception(Money::Currency::UnknownCurrency)
    end
  end

end
