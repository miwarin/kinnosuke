# coding: utf-8

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

td[0] <td nowrap>14</td>                                   日
td[1]
td[2] <td nowrap>月</td>                                   曜日
td[3]
td[4] <td nowrap>平日</td>                                 カレンダー
td[5]
td[6] <td nowrap>◎キヤノン2</td>                          勤務条件
td[7]
td[8] <td nowrap>有休（1日）</td>                          届出内容
td[9]
td[10] <td nowrapstyle="color:#999999;"> </td>             状況区分
td[11]
td[12] <td nowrap>07:30</td>                               有休(1日)
td[13]
td[14] <td nowrap> </td>                                   有休(時間)
td[15]
td[16] <td nowrap> </td>                                   出社
td[17]
td[18] <td nowrap> </td>                                   退社
td[19]
td[20] <td nowrap> </td>                                   実働時間
td[21]
td[22] <td nowrap> </td>                                   残業終了
td[23]
td[24] <td nowrap> </td>                                   法内超過
td[25]
td[26] <td nowrap> </td>                                   法外超過
td[27]
td[28] <td nowrap> </td>                                   深夜労働
td[29]
td[30] <td nowrap> </td>                                   不足時間
td[31]
td[32] <td nowrapalign="left">私用</td>                    備考
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

require 'mechanize'

module MSKinnosuke
  class Kinnosuke
    def initialize(config)
      @config = config
    end
    
    def login
      agent = Mechanize.new
      
      # ログイン
      agent.get('https://www.4628.jp/')
      agent.page.form_with(:id => 'form1'){|f|
        f.field_with( :name => 'y_companycd' ).value = @config.prof_company
        f.field_with( :name => 'y_logincd' ).value = @config.prof_login
        f.field_with( :name => 'password' ).value = @config.prof_password
        f.checkboxes[ 0 ].check
        f.click_button
      }
      return agent
    end
    
    def summer_time?(a_date)
      s = Time.parse("07/07")
      e = Time.parse("09/26")
      return (a_date >= s) && (a_date <= e)
    end
  
    # 定時から10分以内に退勤したか？
    def get_overtime_start(a_date)
      if summer_time?(a_date)
        return "16:25"
      else
        return "17:10"
      end
    end
    
    def get_record(page_body)
      fixnum = 0
      fixnum = 2 if Time.new.mon == 7
      Nokogiri::HTML.parse(page_body).root.xpath("//tr[starts-with(@id, 'fix_#{fixnum}_')]")
    end
    
  end
end
