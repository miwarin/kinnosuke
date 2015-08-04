# coding: utf-8

require 'rubygems'
require 'mechanize'
require 'mail'
require 'pp'

require './mskmail'
require './mskconfig'
require './mskinnosuke'


=begin

HTML はこう

  <tr class="bgcolor_white" id="fix_0_18" align="center">
  <td nowrap="nowrap">18</td>                              日
  <td nowrap="nowrap">水</td>                              曜日
  <td nowrap="nowrap">平日</td>                            カレンダー
  <td nowrap="nowrap">◎キヤノン</td>                      勤務条件
  <td nowrap="nowrap">有休（1日）</td>                     届出内容
  <td style="color:#999999;" nowrap="nowrap">&nbsp;</td>   状況区分
  <td nowrap="nowrap">07:30</td>                           有休(1日)
  <td nowrap="nowrap">&nbsp;</td>                          有休(時間)
  <td nowrap="nowrap">&nbsp;</td>                          出社
  <td nowrap="nowrap">&nbsp;</td>                          退社
  <td nowrap="nowrap">&nbsp;</td>                          実働時間
  <td nowrap="nowrap">&nbsp;</td>                          残業終了
  <td nowrap="nowrap">&nbsp;</td>                          法内超過
  <td nowrap="nowrap">&nbsp;</td>                          法外超過
  <td nowrap="nowrap">&nbsp;</td>                          深夜労働
  <td nowrap="nowrap">&nbsp;</td>                          不足時間
  <td align="left" nowrap="nowrap">私用</td>               備考

Nokogiri するとこう

td[0] <td nowrap>14</td>
td[1]
td[2] <td nowrap>月</td>
td[3]
td[4] <td nowrap>平日</td>
td[5]
td[6] <td nowrap>◎キヤノン2</td>
td[7]
td[8] <td nowrap>有休（1日）</td>                  <= これと
td[9]
td[10] <td nowrapstyle="color:#999999;"> </td>
td[11]
td[12] <td nowrap>07:30</td>
td[13]
td[14] <td nowrap> </td>
td[15]
td[16] <td nowrap> </td>
td[17]
td[18] <td nowrap> </td>
td[19]
td[20] <td nowrap> </td>
td[21]
td[22] <td nowrap> </td>
td[23]
td[24] <td nowrap> </td>
td[25]
td[26] <td nowrap> </td>
td[27]
td[28] <td nowrap> </td>
td[29]
td[30] <td nowrap> </td>
td[31]
td[32] <td nowrapalign="left">私用</td>               <= これをチェック
td[33]
td[34] <tdid="move_td_wait_2014714"colspan="3"class="bgcolor_white"align="center"style="display:none;"><divid="progress_move_2014714"class="txt_15_b_message_red">処理中</div></td>
td[35]
td[36] <td nowrapid="browse_td_edit_2014714"><br></td>
td[37]
td[38] <td nowrapid="browse_td_delete_2014714"><br></td>
td[39]
td[40] <td nowrapid="browse_td_inkan_2014714"><br></td>
td[41]
=end


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

    doc = Nokogiri::HTML.parse(page_body)

    # tr のうち fix_ で始まる id を抽出
    # e.g.
    #   <tr class="bgcolor_yasumi_red" id="fix_0_1" align="center">
    #   <tr class="bgcolor_white" id="fix_0_2" align="center">
    #   <tr class="bgcolor_white" id="fix_0_3" align="center">
    #     :
    doc.root.xpath("//tr[starts-with(@id, 'fix_2_')]").each {|tr|
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

