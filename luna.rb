require './moonlight'
require 'httparty'
require 'nokogiri'
require 'rubygems'
require 'bundler/setup'
require 'active_record'
require 'axlsx'
require 'logger'
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

# if ARGV.nil? || ARGV.length < 2
#   puts "---command---"
#   puts "ruby luna.rb [key words] [search page nubers]"
#   exit(0)
# end
puts "请输入开始页数..."
NUM_FROM = gets
puts "请输入结束页数..."
NUM_TO = gets
puts "请输入关键字..."
KEY = gets
# NUM_FROM,NUM_TO = gets, KEY = ARGV

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



class Item < ActiveRecord::Base
  belongs_to :store
  # attr_accessor :matched, :desc, :async, :matched_text
  # before_validation :parse_and_search

  def search text, reg
    return if text.nil? || text.empty?
    match = text.match(/^var\s*#{reg}\s*=\s*'(.*)/)
    response = Nokogiri::HTML(match && match[1])
    match = response.xpath("//text()").to_s.match(/([微Vv]|wei).*信([\s]|[\u4e00-\u9fa5]|[：，。‘“’”？、@！#￥%……&\*（）\|\+\=\_\!\$%\,\.\?\/;；～~]){0,5}([a-zA-Z][\w\-]{6,20})/)
    if match
      self.matched = true
      self.send("#{reg}=".to_sym, response)
      self.matched_text = match[3]
    end
  end

  def parse_and_search
    search(Moonlight.request("http://#{desc_url}", Moonlight::JS_HEADER).encode!("utf-8", :undef => :replace, :replace => "?", :invalid => :replace), "desc") if desc_url
    # search(parse_url(async_url), "async")
    self.save!
  end

end


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

  def self.calculate_level item
    return unless item['shopcard']
    if item['shopcard']['levelClasses'].size.zero?
      "无"
    else
      "#{item['shopcard']['levelClasses'].size}#{ LEVEL[item['shopcard']['levelClasses'][0]['levelClass']] }"
    end
  end

  def self.parse store_json
    store_json.each do |item|
      printf "."
      return unless item['shopcard']
      store = Store.create!(
        level: self.calculate_level(item),
        user_id: item["user_id"],
        is_tmall: item['shopcard']['isTmall'],
        nick: item['nick'],
        link: item['shopLink']
      ) unless Store.find_by_nick(item['nick'])
      self.create_items store, item["detail_url"]

    end
  end

  def self.create_items store, detail_url
    return if detail_url.nil? || detail_url.empty? || store.nil?
    params_hash = CGI.parse(URI.parse(detail_url).query)
    if detail_url.start_with?("//item.taobao.com")
      detail_url = "http://world.taobao.com/item/#{params_hash.delete("id").first}.htm?#{URI.encode_www_form(params_hash.merge("fromSite"=> "main"))}"
    elsif detail_url.start_with?("//detail.tmall.com")
      detail_url = "http://world.tmall.com/item/#{params_hash.delete("id").first}.htm?#{URI.encode_www_form(params_hash)}"
    end

    response = Moonlight.request(detail_url, Moonlight::SHOP_HEADER).to_s
    desc_url = (match = response.match(/descUrl\s*:\s*"(\/\/)(.*?)(["]\s*[,])/)) && match[2]
    # async_url =(match = response.match(/asyncUrl\s*:\s*"(\/\/)(.*?)(["]\s*[}\);])/)) && match[2]
    store.items.create(
      detail_url: detail_url,
      desc_url: desc_url,
      async_url: nil
    ) unless store.items.pluck(:detail_url).include? detail_url
  end
end

class Page < ActiveRecord::Base
  serialize :store_json, Array
  @@total_page = nil

  def self.pre_get
    if @@total_page.nil?
      pre_url = "https://s.taobao.com/search?q=#{ URI::encode(KEY) }&bcoffset=-7&ntoffset=-7&p4plefttype=3%2C1&p4pleftnum=1%2C3&s="
      @@total_page = get_mods(pre_url)["pager"]["data"]["totalPage"].to_i
    end
  end

  def self.import
    pre_get
    num_to = NUM_TO.to_i
    if @@total_page < num_to
      puts "总共才#{@@total_page}页数据，不信自己看看！！"
      num_to = @@total_page
    end
    num_to = @@total_page < NUM_TO.to_i ? @@total_page : NUM_TO.to_i
    (NUM_FROM.to_i..num_to.to_i).each do |n|
      printf "."
      url = "https://s.taobao.com/search?q=#{ URI::encode(KEY) }&bcoffset=-7&ntoffset=-7&p4plefttype=3%2C1&p4pleftnum=1%2C3&s=#{ (n-1) * 44 }"
      mods = get_mods url
      Page.create!(store_json: mods["itemlist"]["data"]["auctions"])
    end
  end

  def self.get_mods url
    response = Moonlight.request(url, Moonlight::PAGE_HEADER).to_s
    js_str = Nokogiri::HTML(response).xpath("//script")[4].to_s
    hash_str = (match = js_str.match(/(g_page_config\s*=\s*)(.*?)([}][;])/)) && match[2]+"}"
    JSON.parse(hash_str)["mods"]
  end
  def self.test
    # return unless link
    response = Moonlight.request("https://item.taobao.com/item.htm?id=35805349371&abbucket=6", Moonlight::SHOP_HEADER).to_s.encode!("utf-8", :undef => :replace, :replace => "?", :invalid => :replace)
    puts response
  end
end

# Page.import
# Page.all.each do |p|
#   Store.parse p.store_json
# end

# Item.all.each do |item|
#   item.parse_and_search
# end
# Moonlight.export Item.where(matched: true)

# Page.destroy_all
# Store.destroy_all
# Item.destroy_all

Page.test





