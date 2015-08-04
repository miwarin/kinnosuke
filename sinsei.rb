# coding: utf-8

require 'rubygems'
require 'mechanize'
require 'mail'
require 'pp'

require './mskmail'
require './mskconfig'
require './mskinnosuke'

class Sinsei
  def initialize(config_path)
    @config = MSKinnosuke::Config.new(config_path)
    @mail = MSKinnosuke::MailSender.new(@config)
    @kinn = MSKinnosuke::Kinnosuke.new(@config)
  end
  
  def check_unapproved
    # debug
#    body_file = File.join( File.dirname(__FILE__), './hoge.txt' )
#    page_body = File.open( body_file ).read()
    
    page_body = page_get
    page_body = NKF.nkf('-w', page_body)

    unapproved = search_unapproved(page_body, @config.members)
    if unapproved.length == 0
      return
    end

    body = "申請 未承認のメンバー:\n\n"
    body << unapproved.join("\n")
    puts body
    
    @mail.send('勤怠 申請 未承認', body)
  end
  

  def page_get
  
    agent = @kinn.login()

    # 申請決済ページ
    page = agent.get('https://www.4628.jp/?module=acceptation&action=acceptation')
    
    # [未承認] を選択して [検索] をクリック
    page.form_with(:id => "search_form") {|form|
      form['search_acceptation_status'] = '2'
      form.click_button
    }
    
    text = agent.page.body
    
    return text
  end

  def search_unapproved(page_body, members)
    unapproved ||= []
    
    members.each {|member|
      if page_body.include?(member)
        unapproved << member
      end
    }
    
    return unapproved
  end
end


def main(argv)
  if argv.length == 1
    config_path = argv.shift
  else
    config_path =  File.join( File.dirname(__FILE__), "./kinnosuke.conf" )
  end
  k = Sinsei.new(config_path)
  k.check_unapproved
end

main(ARGV)

