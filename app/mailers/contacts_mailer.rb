require_dependency 'email/message_builder'

class ContactsMailer < ActionMailer::Base
  include Email::BuildEmailHelper

  def contact_us(message)
    @message = message
    mail(to: 'atanych@gmail.com', subject: 'From Form Contact Us')
  end
end
