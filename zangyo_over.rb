# coding: utf-8

require 'rubygems'
require 'mechanize'
require 'mail'
require 'pp'
require 'time'

require './mskmail'
require './mskconfig'
require './mskinnosuke'

class ZangyoOver
  def initialize(config_path)
    @config = MSKinnosuke::Config.new(config_path)
    @mail = MSKinnosuke::MailSender.new(@config)
    @kinn = MSKinnosuke::Kinnosuke.new(@config)
  end
  
  def check
    return unless @kinn.working?

    no_reason_members = ""
    @config.riyuu_members.each {|name, number|
      uri = "https://www.4628.jp/?module=acceptation&action=browse_timesheet&appl_id=#{number}"
      @kinn.agent.get(uri)
      reason = page_scan(@kinn.agent.page.body)
      next if reason.empty?
      no_reason_members << "#{name} #{reason.join(" ")}\n"
    }
    
    return if no_reason_members.empty?

    body = "退社時刻が残業申請を超過 又は残業未申請:\n\n"
    body << no_reason_members
    puts body
    
    @mail.send('勤怠 退社が残業申請を超過', body)
  end
  
  def page_scan(page_body)
    no_reason ||= []
    @kinn.get_record(page_body).each {|tr|
      day = tr.children[0].text
      taisha = tr.children[18].text.gsub(/\s+/, '').delete("\xC2\xA0")
      zangyo = tr.children[22].text.gsub(/\s+/, '').delete("\xC2\xA0")
      
      next if taisha == ""
      
      t1 = Time.parse(taisha)
      
      tt = Time.now
      y = tt.year
      m = tt.mon
      a_date = Time.new(y, m, day)
      t2 = Time.parse( @kinn.get_overtime_start( a_date ) )
      
      # 退社が 残業申請時間前ならチェックせず
      next if t1 < t2
      
      if (zangyo == "" ) || (t1 > Time.parse(zangyo))
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
  k = ZangyoOver.new(config_path)
  k.check
end

main(ARGV)

