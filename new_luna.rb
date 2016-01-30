require './moonlight'
require 'httparty'
require 'nokogiri'
require 'rubygems'
require 'bundler/setup'
require 'active_record'
require 'axlsx'
require 'logger'
require 'openssl'

# OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

puts "请输入开始页数..."
NUM_FROM = gets
puts "请输入结束页数..."
NUM_TO = gets
puts "请输入关键字..."
KEY = gets.encode!("utf-8", :undef => :replace, :replace => "?", :invalid => :replace)


ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: 'luna.db'
# ActiveRecord::Schema.define do
#   self.verbose = false

#   create_table :stores do |t|
#     t.string  :level
#     t.string  :link
#     t.string  :user_id
#     t.boolean  :is_tmall
#     t.string  :nick
#     t.text    :weixin_text
#     t.text    :first_auction
#     t.string  :provcity
#   end

#   create_table :items do |t|
#     t.integer :store_id
#     t.string  :detail_url
#     t.integer  :comment_count
#     t.string   :desc_url
#     t.string   :async_url
#     t.text     :desc
#     t.text     :async
#     t.text     :matched_text
#     t.boolean  :matched, default: false
#   end

#   create_table :pages do |t|
#     t.text  :store_json
#   end
# end

class Store < ActiveRecord::Base
  has_many :items
  LEVEL = {
    'icon-supple-level-zuan'=> "钻",
    'icon-supple-level-xin'=> "心",
    'icon-supple-level-guan'=> "皇冠"
  }

  def show_is_tmall
    is_tmall ? "是" : "否"
  end

  def self.parse
    (NUM_FROM.to_i..NUM_TO.to_i).each do |num|
      page_url = "https://shopsearch.taobao.com/search?app=shopsearch&q=#{ URI::encode(KEY) }&js=1&initiative_id=staobaoz_20160121&ie=utf8&s=#{ num * 20 }"
      response = Moonlight.request(page_url, Moonlight::SEARCH_HEADER)
      js_str = Nokogiri::HTML(response).xpath("//script")[5].to_s
      hash_str = JSON.parse((js_str.match(/(g_page_config\s*=\s*)(.*?});/)).try(:[],2))
      hash_str["mods"]["shoplist"]["data"]["shopItems"].each do |item|
        Store.create!(
          level: item['shopIcon']['iconClass'].to_s.split("-").last,
          user_id: item["uid"],
          is_tmall: item['isTmall'],
          nick: item['nick'],
          link: item['shopUrl'].present? && "https:" + item['shopUrl'],
          provcity: item['provcity'],
          first_auction: item['auctionsInshop'].try(:first).try(:[], 'url')
        )
      end
      break if NUM_TO.to_i >= hash_str["mods"]["pager"]["data"]["totalPage"].to_i
    end
  end

  def find_weixin
    return unless link
    response = Moonlight.request(link, Moonlight::SHOP_HEADER).to_s.encode!("utf-8", undef: :replace, :replace => "?", :invalid => :replace)
    self.weixin_text = match_weixin(Nokogiri::HTML(response).xpath("//text()").to_s)
    if !self.weixin_text && first_auction
      response = Moonlight.request("https:" + first_auction, Moonlight::SHOP_HEADER).to_s
      desc_url = (match = response.match(/descUrl\s*:\s*"(\/\/)(.*?)(["]\s*[,])/)).try(:[], 2)
      return unless desc_url
      response = Moonlight.request("http://#{desc_url}", Moonlight::JS_HEADER).to_s.encode!("utf-8", :undef => :replace, :replace => "?", :invalid => :replace)
      response = Nokogiri::HTML(response.match(/^var\s*desc\s*=\s*'(.*)/).try(:[], 1))
      self.weixin_text = match_weixin response.xpath("//text()").to_s
    end
    self.save!
  end

  def match_weixin string
    string.match(/(?i)((v|w|wei|微|薇|wechat)(xin|x|信))([:：\s]|[\u4e00-\u9fa5]){1,3}(([a-zA-Z]|[\w\-]){6,20})/).try(:[], 5)
  end
end

begin
  Store.destroy_all
  Store.parse()
  Store.all.each { | store | store.find_weixin }
  Moonlight.export_stores
rescue Exception => e
  puts "发生错误！联系小白"
  File.open("error.log", "a") do |f|
    f << "[#{Time.now}] "
    e.backtrace.split(",").each {|error| f << error}
    f << "\n\n"
  end
end
