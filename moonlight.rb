class Moonlight

  PAGE_HEADER = {
    "Connection"=> "keep-alive",
    "Pragma"=> "no-cache",
    "Cache-Control"=> "no-cache",
    "Accept"=> "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Upgrade-Insecure-Requests"=> "1",
    "User-Agent"=> "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.106 Safari/537.36",
    "Accept-Encoding"=> "gzip, deflate, sdch",
    "Accept-Language"=> "zh-CN,zh;q=0.8,en;q=0.6",
    "Cookie" => "thw=cn; cna=o5f+DXbU9HsCAWcGVfQY2WNC; miid=6435533376102643923; x=e%3D1%26p%3D*%26s%3D0%26c%3D0%26f%3D0%26g%3D0%26t%3D0; thw=cn; cna=o5f+DXbU9HsCAWcGVfQY2WNC; miid=6435533376102643923; x=e%3D1%26p%3D*%26s%3D0%26c%3D0%26f%3D0%26g%3D0%26t%3D0; _cc_=WqG3DMC9EA%3D%3D; tg=0; alitrackid=www.taobao.com; lastalitrackid=www.taobao.com; _tb_token_=7db3b7fd71e5b; uc3=nk2=&id2=&lg2=; hng=HK%7Czh-tw%7CHKD; tracknick=; mt=ci=0_0&cyk=-1_-1; v=0; cookie2=1cae243c12991a5614477ab81fee61bf; t=4f3dc6221cfef6b6642fb3c891b8558f; l=AtTUjvAuelJNUZJUkqrGxAafJBhGNfgX; isg=1F7DCCDD6C6D69EB533E3851BAFE9F4E; JSESSIONID=4B12A8B69AA56FDFE74CFDBBB3041A8A; _cc_=U%2BGCWk%2F7og%3D%3D; tg=0; _tb_token_=7db3b7fd71e5b; uc3=nk2=&id2=&lg2=; hng=HK%7Czh-tw%7CHKD; tracknick=; mt=ci=0_0&cyk=-1_-1; v=0; cookie2=1cae243c12991a5614477ab81fee61bf; t=4f3dc6221cfef6b6642fb3c891b8558f; l=AsfHKHaEWYtCwKFNBesFChfl13GRzJuu; isg=9F86C184DA9D7775EA9B2D04D18621B8"
  }

  SHOP_HEADER = {
    "Connection"=> "keep-alive",
    "Cache-Control"=> "no-cache",
    "Accept"=> "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "User-Agent"=> "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9",
    "Accept-Encoding"=> "gzip, deflate",
    "Accept-Language"=> "zh-cn",
    "Cookie" => "mt=ci%3D-1_0; _tb_token_=HixXDscQflH1; cna=5hgaDxUVqngCAQZpCXeMAMn6; cookie2=14eda32e786178a94b9c7b1b7d6e6957; hng=HK%7Czh-tw%7CHKD; isg=90904AECCB6295E1AF04FFBD65462161; l=AgYG7M81DMZgUjbYBqD0ig1PRvOIZ0oh; linezing_session=UtQdfhXKOtj3HMvR2itmaO8f_1452485350288VnZx_1; t=194fc3bbf0034816896ece611995ffaf; thw=hk; v=0"
    }

  JS_HEADER = {
    "Accept"=>  "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "User-Agent"=>  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9",
    "Accept-Language"=> "zh-cn",
    "Accept-Encoding"=> "gzip, deflate",
    "Connection"=>  "keep-alive"
  }

  SEARCH_HEADER = {
    "Connection" =>  "keep-alive",
    "Accept"=>  "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
    "Upgrade-Insecure-Requests" =>   "1",
    "User-Agent" =>  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.111 Safari/537.36",
    "Accept-Encoding" => "gzip, deflate, sdch",
    "Content-Type"=> "text/html; charset=utf-8",
    "Accept-Language"=> "zh-CN,zh;q=0.8,en;q=0.6",
    "Cookie"=>  "v=0; cna=tt0oD66sF2ECAdMWkZrOzuPQ; _m_h5_tk=ee15546471fd0f9fa60d56d09147746b_1453458287188; _m_h5_tk_enc=9064e5ad5a1d8e715e1f2a528e7b770f; cookie2=1c3b1638bad8d02ee71cb73846036451; t=a1d76509867ce9d8854014a3200a2f35; uc1=cookie14=UoWyjVtOSdrKGw%3D%3D; _tb_token_=3333ba1d3110b; thw=cn; mt=ci%3D-1_0; l=AsPDOnKJXug5akW2s3nZdxmo041tS1ey; isg=140894EF21A20A1E7EBB2992091DF4F9"

  }



  PARSER_ERROR_TYPE = {
    :changed => "页面内容格式改变"
  }

  def self.request url, headers
    return if url.nil? || url.empty?
    HTTParty.get(url, follow_redirects: true, headers: headers)
  end

  def self.export items
    titles = %w(店铺等级 店铺首页 店铺掌柜 匹配微信号 是否天猫)
    p = Axlsx::Package.new
    p.workbook.add_worksheet(:name => "Basic Worksheet") do |sheet|
      sheet.add_row titles
      items.each do |item|
        sheet.add_row([].tap do |arr|
          arr << item.store.level
          arr << item.store.link
          arr << item.store.nick
          arr << item.matched_text
          arr << item.store.show_is_tmall
        end)
      end
    end and nil
    p.serialize("weixin.xlsx")
    File.open('weixin.xlsx').read
  end

  def self.export_stores
    titles = %w(店铺等级 店铺首页 店铺掌柜 匹配微信号 是否天猫 所在地)
    p = Axlsx::Package.new
    p.workbook.add_worksheet(:name => "Basic Worksheet") do |sheet|
      sheet.add_row titles
      Store.all.each do |store|
        sheet.add_row([].tap do |arr|
          arr << store.level
          arr << store.link
          arr << store.nick
          arr << store.weixin_text
          arr << store.show_is_tmall
          arr << store.provcity
        end)
      end
    end and nil
    p.serialize("weixin.xlsx")
    File.open('weixin.xlsx').read

  end

end

