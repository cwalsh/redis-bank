require 'money/bank/base'
require 'active_support/core_ext'

class Money
  module Bank
    # Thrown when an unknown rate format is requested.
    class UnknownRateFormat < StandardError; end

    # Class for aiding in exchanging money between different currencies. By
    # default, the +Money+ class uses an object of this class (accessible
    # through +Money#bank+) for performing currency exchanges.
    #
    # @example
    #   bank = Money::Bank::RedisBank.new redis_client
    #   bank.add_rate("USD", "CAD", 1.24515)
    #   bank.add_rate("CAD", "USD", 0.803115)
    #
    #   c1 = 100_00.to_money("USD")
    #   c2 = 100_00.to_money("CAD")
    #
    #   # Exchange 100 USD to CAD:
    #   bank.exchange_with(c1, "CAD") #=> #<Money @cents=1245150>
    #
    #   # Exchange 100 CAD to USD:
    #   bank.exchange_with(c2, "USD") #=> #<Money @cents=803115>
    class RedisBank < Base
      KEY='redis_bank_exchange_rates'

      def initialize(redis_client, &block)
        super(&block)
        @redis_client = redis_client
      end

      # This allows the user to define a method of obtaining exchange rates
      # should they not exist in redis.
      # Once the new set of rates is obtained, it is stored in redis if
      # write_through is set to true.
      #
      # @example
      #   bank = Money::Bank::RedisBank.new redis_client
      #   bank.set_fallback(true) { {"gbp_to_aud" => rand, "jpy_to_aud" => rand} }
      #   bank.rates # => {"gbp_to_aud"=>"1.75", "jpy_to_aud"=>"0.002"}
      #   redis_client.del "redis_bank_exchange_rates" # Oops!
      #   bank.rates # => {"gbp_to_aud"=>"0.861522064707917",
      #                    "jpy_to_aud"=>"0.552042440462882"}
      #
      def set_fallback(write_through, &block)
        @write_through = write_through
        @fallback = block
      end

      # hash of exchange rates
      def rates
        begin
          rates = @redis_client.hgetall KEY
          if rates.blank? && @fallback
            rates = @fallback.call
            @redis_client.mapped_hmset KEY, rates if @write_through
          end
          rates
        rescue
          if @fallback
            @fallback.call
          else
            raise
          end
        end
      end

      # Exchanges the given +Money+ object to a new +Money+ object in
      # +to_currency+.
      #
      # @param  [Money] from
      #         The +Money+ object to exchange.
      # @param  [Currency, String, Symbol] to_currency
      #         The currency to exchange to.
      #
      # @yield [n] Optional block to use when rounding after exchanging one
      #  currency for another.
      # @yieldparam [Float] n The resulting float after exchanging one currency
      #  for another.
      # @yieldreturn [Integer]
      #
      # @return [Money]
      #
      # @raise +Money::Bank::UnknownRate+ if the conversion rate is unknown.
      #
      # @example
      #   bank = Money::Bank::RedisBank.new redis_client
      #   bank.add_rate("USD", "CAD", 1.24515)
      #   bank.add_rate("CAD", "USD", 0.803115)
      #
      #   c1 = 100_00.to_money("USD")
      #   c2 = 100_00.to_money("CAD")
      #
      #   # Exchange 100 USD to CAD:
      #   bank.exchange_with(c1, "CAD") #=> #<Money @cents=1245150>
      #
      #   # Exchange 100 CAD to USD:
      #   bank.exchange_with(c2, "USD") #=> #<Money @cents=803115>
      def exchange_with(from, to_currency)
        return from if same_currency?(from.currency, to_currency)

        rate = get_rate(from.currency, to_currency)
        unless rate
          raise UnknownRate, "No conversion rate known for '#{from.currency.iso_code}' -> '#{to_currency}'"
        end
        _to_currency_  = Currency.wrap(to_currency)

        cents = BigDecimal.new(from.cents.to_s) / (BigDecimal.new(from.currency.subunit_to_unit.to_s) / BigDecimal.new(_to_currency_.subunit_to_unit.to_s))

        ex = cents * BigDecimal.new(rate.to_s)
        ex = ex.to_f
        ex = if block_given?
               yield ex
             elsif @rounding_method
               @rounding_method.call(ex)
             else
               ex.to_s.to_i
             end
        Money.new(ex, _to_currency_)
      end

      # Registers a conversion rate and returns it (uses +#set_rate+).
      #
      # @param [Currency, String, Symbol] from Currency to exchange from.
      # @param [Currency, String, Symbol] to Currency to exchange to.
      # @param [Numeric] rate Rate to use when exchanging currencies.
      #
      # @return [Numeric]
      #
      # @example
      #   bank = Money::Bank::VariableExchange.new
      #   bank.add_rate("USD", "CAD", 1.24515)
      #   bank.add_rate("CAD", "USD", 0.803115)
      def add_rate(from, to, rate)
        set_rate from, to, rate
      end

      # Set the rate for the given currencies.
      #
      # @param [Currency, String, Symbol] from Currency to exchange from.
      # @param [Currency, String, Symbol] to Currency to exchange to.
      # @param [Numeric] rate Rate to use when exchanging currencies.
      #
      # @return [Numeric]
      #
      # @example
      #   bank = Money::Bank::VariableExchange.new
      #   bank.set_rate("USD", "CAD", 1.24515)
      #   bank.set_rate("CAD", "USD", 0.803115)
      def set_rate(from, to, rate)
        @redis_client.hset KEY, rate_key_for(from, to), rate
      end
      #
      # @param [Currency, String, Symbol] from Currency to exchange from.
      # @param [Currency, String, Symbol] to Currency to exchange to.
      #
      # @return [Numeric]
      #
      # @example
      #   bank = Money::Bank::VariableExchange.new
      #   bank.set_rate("USD", "CAD", 1.24515)
      #   bank.set_rate("CAD", "USD", 0.803115)
      #
      #   bank.get_rate("USD", "CAD") #=> 1.24515
      #   bank.get_rate("CAD", "USD") #=> 0.803115
      def get_rate(from, to)
        from = from.downcase.strip if from.is_a? String
        to = to.downcase.strip if to.is_a? String
        return 1.0 if from == to
        begin
          rate = @redis_client.hget KEY, rate_key_for(from, to)
          if rate.blank? && @fallback
            rates = @fallback.call
            rate = rates[rate_key_for(from, to)]
            @redis_client.mapped_hmset KEY, rates if @write_through
          end
          rate
        rescue
          if @fallback
            rates = @fallback.call
            rate = rates[rate_key_for(from, to)]
          else
            raise
          end
        end
      end

      # Return the rate hashkey for the given currencies.
      #
      # @param [Currency, String, Symbol] from The currency to exchange from.
      # @param [Currency, String, Symbol] to The currency to exchange to.
      #
      # @return [String]
      #
      # @example
      #   rate_key_for("USD", "CAD") #=> "usd_to_cad"
      def rate_key_for(from, to)
        "#{Currency.wrap(from).iso_code}_to_#{Currency.wrap(to).iso_code}".downcase
      end
    end
  end
end
