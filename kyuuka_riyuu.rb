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
  
  def check
    
    no_reason_members = ""
    
    @config.riyuu_members.each {|name, number|
      page_body = page_get(number)
      page_body = NKF.nkf('-w', page_body)
      reason = page_scan(page_body)
      next if reason.empty?
      no_reason_members << "#{name} #{reason.join(" ")}\n"
    }
    
    return if no_reason_members.empty?

    body = "休暇理由 未記入のメンバーと日にち:\n\n"
    body << no_reason_members
    puts body
    
    @mail.send('勤怠 休暇理由 未記入', body)
  end
  

  def page_get(employee_number)
    agent = @kinn.login()

    # 社員ごとの出勤簿
    uri = "https://www.4628.jp/?module=acceptation&action=browse_timesheet&appl_id=#{employee_number}"
    agent.get(uri)
    
    # 隠されているだけなので javascript をがんばったり form を取得したりする必要もない
    #agent.page.link_with(:href => /javascript:switch_tab\(2, 3, 0\)/).click
    #form = agent.page.form_with(:name => 'submit_form2')
    
    return agent.page.body
  end

  def page_scan(page_body)
  
    no_reason ||= []

    @kinn.get_record(page_body).each {|tr|
      day = tr.children[0].text
      
      # 見た目空白なんだが 0xC2A0 (UTF-8) が入ってるので削除。なんだこれ
      v = tr.children[8].text.gsub(/\s+/, '').delete("\xC2\xA0")
      r = tr.children[32].text.gsub(/\s+/, '').delete("\xC2\xA0")

      is_vacation = v.include?("有休")
      is_reason = r.empty?
      
      if (is_vacation == true) && (is_reason == true)
        no_reason << day
      end
    }
    return no_reason
  end
end

def main(argv)
  if argv.length == 1
    config_path = argv.shift
  else
    config_path =  File.join( File.dirname(__FILE__), "./kinnosuke.conf" )
  end
  k = Sinsei.new(config_path)
  k.check
end

main(ARGV)

