module Txter
  class << self
    def gateway
      Txter::Gateway.current
    end

    delegate :deliver, :to => :gateway
    delegate :unblock, :to => :gateway

    def log(msg)
      if defined?(Rails)
        Rails.logger.info msg
      else
        STDOUT.puts msg
      end
    end

    def numerize(numberish)
      numberish.to_s.scan(/\d+/).join
    end

    def internationalize(given_number)
      number = numerize(given_number)
      case number.size
      when 10
        "+1#{number}"
      when 11
        "+#{number}"
      when 12
        number =~ /\+\d(11)/ ? number : nil
      else
        nil
      end
    end

    def confirmation_message(confirmation_code)
      "Code: #{confirmation_code} Enter code on web to verify phone. Msg&data rates may apply. Freq set by u. T&C & support on web site. Txt HELP for help"
    end

    def generate_confirmation_code
      chars = (0..9).to_a + ('A'..'Z').to_a
      (0...6).collect { chars[Kernel.rand(chars.length)] }.join
    end
  end
end

require File.join(File.dirname(__FILE__), 'configuration')
require File.join(File.dirname(__FILE__), 'gateway')
require File.join(File.dirname(__FILE__), 'contactable')
require File.join(File.dirname(__FILE__), 'controller')
