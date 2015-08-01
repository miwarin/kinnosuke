# coding: utf-8

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
  end
end
