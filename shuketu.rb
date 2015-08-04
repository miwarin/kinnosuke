# coding: utf-8


require 'openssl'

require 'rubygems'
require 'mechanize'
require 'mail'
require 'pp'

require './mskconfig'
require './mskinnosuke'

class Sinsei
  def initialize(config_path)
    @config = MSKinnosuke::Config.new(config_path)
    @kinn = MSKinnosuke::Kinnosuke.new(@config)
  end
  
  def check_unapproved
    # debug
#    body_file = File.join( File.dirname(__FILE__), './hoge.txt' )
#    page_body = File.open( body_file ).read()
    
    page_body = page_get
    page_body = NKF.nkf('-s', page_body)
    puts page_body
    
    #tr_submit_form > table:nth-child(6) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(2)
    #tr_submit_form > table:nth-child(6) > tbody:nth-child(1) > tr:nth-child(1) > td:nth-child(3) > button:nth-child(1)
    

  end
  

  def page_get
    agent = @kinn.login()
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

