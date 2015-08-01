# 勤之助チェック

[勤之助](https://www.4628.jp/ "勤之助") の機能がいろいろ残念なので処理を自動化します。

# 要求

ruby 1.9 以上

# インストール

外部ライブラリの取得に必要となるBundlerインストールします。

    gem install bundler

kinnosuke の書庫を取得し、展開したあとに `bundle install` コマンドを実行して外部ライブラリをインストールします。

    cd kinnosuke
    bundle install

kinnosuke.conf を編集します。

prof_ は勤之助の情報です。members にチェックしたい従業員名を記入します。部下の氏名を列挙するといいでしょう。名字と名前は空白であけてください。


```ruby
# coding: utf-8
# -*- mode: ruby -*-
Config = {
  :prof_company => 'hogehoge',
  :prof_login => 'ログインID',
  :prof_password => 'パスワード',

  :mail_from => 'miwa_ssm@msoft.co.jp',
  :mail_to => 'miwa_ssm@msoft.co.jp',

  :mail_server_address => 'smtp.example.co.jp',
  :mail_server_port => 25,
  :mail_server_domain => 'example.co.jp',
  :mail_server_user_name => 'user',
  :mail_server_password => 'パスワード',

  :members => [
    "苗字 名前",
    "苗字 名前",
  ],

  :riyuu_members => {
    "苗字" => 77777,
    "苗字" => 99999,
  }
}
```

Ruby コマンドプロンプトで実行します。

    ruby sinsei.rb

# スクリプト

##申請チェック

sinsei.rb

勤之助の「各種申請」の「メール配信」が実質的に機能不全に陥っています。

sinsei.rb は「各種申請」で申請されたかどうかをチェックし、申請されていればメールで通知します。

## 有給休暇理由有無チェック

kyuuka_riyuu.rb

勤之助は【お察しください】我々はいつまでこの不毛な戦いを続けなければならないのか。

kyuuka_riyuu.rb は「出勤簿」の有給休暇取得日の「備考」に休暇理由が書かれているかどうかをチェックし、空欄であればメールで通知します。

チェックしたいメンバーを kinnosuke.conf に記入します。ID は 申請決裁 でメンバーの出勤簿を表示すると URI に含まれる「appl_id=xxxxxx」を書きます。( 自分自身のものはチェック出来ない？ 調査中です )

```ruby
  :riyuu_members => {
    "苗字" => 77777,
    "苗字" => 99999,
  }
```


## 退社時間が残業申請時間を超過したかチェック

【お察しください】

zangyo_over.rb

設定ファイルは riyuu_members の設定を流用します。

riyuu_members を書いておけばよいです。
