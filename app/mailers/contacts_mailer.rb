require_dependency 'email/message_builder'

class ContactsMailer < ActionMailer::Base
  include Email::BuildEmailHelper

  def contact_us(message)
    @message = message
    mail(to: 'atanych@gmail.com', subject: I18n.t('contact_success_message_email_title'), from: 'server@sportenter.co.il')
  end
end
