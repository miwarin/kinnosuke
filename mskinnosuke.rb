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
  end
end
