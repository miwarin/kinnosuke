# coding: utf-8

require 'mechanize'
require 'mail'
require 'pp'
require "gnuplot"

require './mskmail'
require './mskconfig'
require './mskinnosuke'

class ZangyoTotal
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

    @kinn.get_record(page_body).each {|tr|
      day = tr.children[1].text
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
  k = ZangyoTotal.new(config_path)
  k.check
end

main(ARGV)

