require 'bundler/inline'
# require 'json'

gemfile install: true do
  source 'https://rubygems.org/'
  gem 'httparty'
  gem 'nokogiri'
end

# if ARGV.nil? || ARGV.length < 2
#   puts "---command---"
#   puts "ruby luna.rb [key words] [search page nubers]"
#   exit(0)
# end

NUM, KEY = ARGV

HEADERS = {
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

HED = {
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

class Collector
  def self.collect_urls
    shop_items = []
    (0..NUM.to_i).step(44) do |n|
      url = "https://s.taobao.com/search?q=#{URI::encode(KEY)}&bcoffset=-7&ntoffset=-7&p4plefttype=3%2C1&p4pleftnum=1%2C3&s=#{NUM}"
      puts url
      response = HTTParty.get(url,follow_redirects: true, headers: HEADERS)
      # puts response
      html_doc_json = Nokogiri::HTML(response).xpath("//script")[4].to_s.match(/(g_page_config\s*=\s*)(.*?)([}][;])/)[2]+"}"
      JSON.parse(html_doc_json)["mods"]["itemlist"]["data"]["auctions"].each do |item|
        printf "."
        detail_url = item["detail_url"]
        puts detail_url

        next if detail_url.nil? || detail_url.empty?
        if detail_url.start_with?("//item.taobao.com")
          params_hash = CGI.parse(URI.parse(detail_url).query).merge("fromSite": "main")
          shop_items << "http://world.taobao.com/item/#{params_hash.delete("id").first}.htm?#{URI.encode_www_form(params_hash)}"
        elsif detail_url.start_with?("https://click.simba.taobao.com")
          shop_items << detail_url
        end
        puts item['shopcard']['isTmall']
      end
    end
    sleep(2)
    shop_items.uniq!
    shop_items
  end

  def self.get_key_url
    js_urls = []
    self.collect_urls.each do |uri|
      printf "#"
      response = HTTParty.get(uri, follow_redirects: true, headers: HED).to_s
      desc_url = (match = response.match(/descUrl\s*:\s*"(\/\/)(.*?)(["]\s*[,])/)) && match[2]
      async_url =(match = response.match(/asyncUrl\s*:\s*"(\/\/)(.*?)(["]\s*[,])/)) && match[2]
      js_urls << desc_url if desc_url
      js_urls << async_url if async_url
    end
    js_urls.uniq!
    js_urls
  end

  def self.collect_targets
    self.get_key_url.each do |uri|
      printf("*")
      response = HTTParty.get("http://#{uri}", follow_redirects: true, headers: HED).to_s.encode("utf-8")
      sub_text = (match = response.match(/^var\s*desc\s*=\s*'(.*)/)) && match[1]
      text = Nokogiri::HTML(sub_text).css("span").text
      puts uri
      puts text
      if text.match(/微.*信/)
        File.open("xxx.txt", "a") do |f|
          f << text+"\n"
          f << "###################################################################################################################################################" + "\n"
        end
      end
    end
  end
  # http://osdsc.alicdn.com/i3/520/531/525539353293/TB11M8.LXXXXXc3XXXX8qtpFXlX.desc?var=desc&sign=452c669aa8934205223f2fb0ee9a13fe&lang=gbk&t=1450875373

  def self.test
    response = HTTParty.get("http://detail.tmall.com/item.htm?id=521821590375&ad_id=&am_id=&cm_id=140105335569ed55e27b&pm_id=&abbucket=4", follow_redirects: false, headers: JS_HEADER).to_s
    puts response.match(/descUrl\s*:\s*"(\/\/)(.*?)(["]\s*[,])/)[2]
  end

end

Collector.collect_targets
