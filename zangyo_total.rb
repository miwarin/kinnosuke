# coding: utf-8

# ruby 2.0 のみ ( ruby 2.2 は nokogiri が未対応 )

require 'mechanize'
require 'mail'
require 'pp'
require 'time'
require "gnuplot"

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


class Sinsei
  def initialize(config_path)
    @config = MSKinnosuke::Config.new(config_path)
    @mail = MSKinnosuke::MailSender.new(@config)
    @kinn = MSKinnosuke::Kinnosuke.new(@config)
    @graph_file = './over.png'
  end
  
  def check
    all_hougai ||= {}
    no_reason_members = ""
    
    @config.riyuu_members.each {|name, number|
      page_body = page_get(number)
#      page_body = NKF.nkf('-w', page_body)
      all_hougai[name] = page_scan(page_body)
    }
    
    plot( all_hougai )
    @mail.send( '残業時間合計', 'グラフ', @graph_file )
  end
  
  def page_get(employee_number)
    agent = @kinn.login()
    uri = "https://www.4628.jp/?module=acceptation&action=browse_timesheet&appl_id=#{employee_number}"
    agent.get(uri)
    return agent.page.body
  end

  def page_scan(page_body)

    totals = []
    total = 0

    doc = Nokogiri::HTML.parse(page_body)
    
    fixnum = 0
    fixnum = 2 if Time.new.mon == 7
    
    doc.root.xpath("//tr[starts-with(@id, 'fix_#{fixnum}_')]").each {|tr|
      day = tr.children[1].text
#      hougai = tr.children[26].text.gsub(/\s+/, '').delete("\xC2\xA0")
      hougai = tr.children[27].text.gsub(/\s+/, '')

      ten = 0
      one = 0
      if hougai != ""
        sp = hougai.split(':')
        ten = sp[0].to_i
        one = sp[1].to_i
      end
      total += ten * 60 + one
      totals << (total / 60)
    }
    
    return totals
    
  end
  
  def plot(all_hougai)
    Gnuplot.open do |gp|
      Gnuplot::Plot.new( gp ) do |plot|
        plot.title  "残業時間推移"
        plot.xlabel "日付"
        plot.ylabel "残業時間"
        plot.terminal "png"
        plot.output @graph_file
        days = nil
        all_hougai.each {|name, hougai|
          puts "#{name} #{hougai}"
          days = (0..hougai.length).map(&:to_i)
          plot.data << Gnuplot::DataSet.new( [days, hougai] ) do |ds|
            ds.with = "lines"
            ds.linewidth = 2
            ds.title = name
          end
        }

        limit = Array.new(days.length, 40)
        plot.data << Gnuplot::DataSet.new( [days, limit] ) do |ds|
          ds.with = "lines"
          ds.linewidth = 1
          ds.title = "40h"
        end

      end
    end
  end
end

def main(argv)
  config_path =  File.join( File.dirname(__FILE__), "./kinnosuke.conf" )
  k = Sinsei.new(config_path)
  k.check
end

main(ARGV)

