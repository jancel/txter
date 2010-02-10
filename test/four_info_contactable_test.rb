require File.join(File.dirname(__FILE__), 'test_helper')

class FourInfoContactableTest < ActiveSupport::TestCase

  ValidationError = '<?xml version="1.0" encoding="UTF-8"?>
<response>
  <status>
    <id>4</id>
    <message>Validation Error</message>
  </status>
</response>'
  ValidationSuccess = '<?xml version=”1.0” ?>
<response>
  <requestId>F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6</requestId>
  <confCode>123abc</confCode>
  <status>
    <id>1</id>
    <message>Success</message>
  </status>
</response>'
  SendMsgSuccess = '<?xml version="1.0" ?>
<response>
  <requestId>F81D4FAE-7DEC-11D0-A765-00A0C91E6BF6</requestId>
  <status>
    <id>1</id>
    <message>Success</message>
  </status>
</response>'

  context "contactable class" do
    setup {
      @klass = Class.new
      @klass.send :include, FourInfo::Contactable
    }
    FourInfo::Contactable::Attributes.each do |attribute|
      should "begin with appropriate default for #{attribute}_column" do
        assert_equal attribute, @klass.send("#{attribute}_column")
      end
      should "allow setting #{attribute}_column" do
        new_column_name = :custom_column
        @klass.send "#{attribute}_column", new_column_name
        assert_equal new_column_name, @klass.send("#{attribute}_column")
      end
    end
  end

  context "contactable instance" do
    setup { @user = User.create! :sms_phone_number => '555-555-5555' }

    context "when phone number is blank" do
      setup { @user.sms_phone_number = nil}
      context "confirming phone number" do
        setup { @user.confirm_sms! }
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
      context "sending message" do
        setup {
          FourInfo::Request.any_instance.stubs(:perform).returns(SendMsgSuccess)
          @worked = @user.send_sms!('message')
        }
        should "not work" do assert !@worked end
        should_not_change "any attributes" do
          @user.attributes.inspect
        end
      end
    end

    context "when phone number exists" do
      setup { @user.sms_phone_number = "206-555-5555"}
      context "confirming phone number" do
        setup {
          FourInfo::Request.any_instance.stubs(:perform).returns(ValidationSuccess)
          @worked = @user.confirm_sms!
        }
        should "work" do assert @worked end
        should "save confirmation number in proper attribute" do
          assert @user.four_info_sms_confirmation_code
        end
        should_change "stored code" do
          @user.four_info_sms_confirmation_code
        end
        should "set sms_confirmed? to true" do
          assert @user.four_info_sms_confirmed?
        end
      end
      context "confirming phone number when the confirmation fails for some reason" do
        setup {
          FourInfo::Request.any_instance.stubs(:perform).returns(ValidationError)
          @worked = @user.confirm_sms!
        }
        should "not work" do assert !@worked end
        should "not save confirmation number" do
          assert @user.four_info_sms_confirmation_code.blank?
        end
        should_not_change "stored code" do
          @user.four_info_sms_confirmation_code
        end
      end
    end

    context "when the number is not confirmed" do
      context "sending a message" do
        setup {
          FourInfo::Request.any_instance.stubs(:perform).returns(SendMsgSuccess)
          @result = @user.send_sms!('message')
        }
        should "send send no messages" do
          assert_equal false, @result
        end
      end
    end
    context "when the number is blocked" do
      setup {
        @user.four_info_sms_blocked = true
        @user.save!
      }
      context "sending a message" do
        setup { @result = @user.send_sms!('message') }
        should "send nothing" do
          assert_equal false, @result
        end
      end
    end
    context "when the number is confirmed" do
      setup {
        FourInfo::Request.any_instance.stubs(:perform).returns(SendMsgSuccess)
        @user.update_attributes!(User.sms_confirmed_column => true)
      }
      context "sending a message" do
        setup { @result = @user.send_sms!('message') }
        should "send send exactly one message messages" do
          assert_equal [true], @result
        end
      end
      context "sending a blank message" do
        setup { @result = @user.send_sms!('') }
        should "send send zero messages" do
          assert_equal false, @result
        end
      end
      context "sending a huge message" do
        context "without the allow_multiple flag" do
          should "raise an error" do
            assert_raises ArgumentError do
              @user.send_sms!("A"*200)
            end
          end
        end
        context "with the allow_multiple flag" do
          setup { @result = @user.send_sms!("A"*200, true) }
          should "send multiple messages" do
            assert_equal [true, true], @result
          end
        end
      end
    end
  end
end