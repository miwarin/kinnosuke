# coding: utf-8

require 'openssl'
I_KNOW_THAT_OPENSSL_VERIFY_PEER_EQUALS_VERIFY_NONE_IS_WRONG = nil
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

require 'rubygems'
require 'mail'

module MSKinnosuke
  class MailSender
    def initialize(config)
      @config = config
    end

    def send(subject, body, attach = nil)
      options = {
        :address              => @config.mail_server_address,
        :port                 => @config.mail_server_port,
        :domain               => @config.mail_server_domain,
        :user_name            => @config.mail_server_user_name,
        :password             => @config.mail_server_password,
        :authentication       => :plain,
        :enable_starttls_auto => true
      }

      Mail.defaults do
        delivery_method :smtp, options
      end

      mail = Mail.new
      mail.from = @config.mail_from
      mail.to =  @config.mail_to
      mail.subject = subject
  #    mail.charset ='iso-2022-jp'
      mail.charset ='utf-8'
      mail.add_file( attach ) if attach
      mail.add_content_transfer_encoding
      mail.body  = body
      mail.deliver
    end
  end
end
