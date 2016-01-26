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

  def self.parse

    Moonlight.request("https://shopsearch.taobao.com/search?app=shopsearch&q=%E5%A5%A2%E4%BE%88%E5%93%81%E4%BB%A3%E8%B4%AD&js=1&initiative_id=staobaoz_20160121&ie=utf8", Moonlight::PAGE_HEADER).to_s
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

  def create_items store, detail_url
    return if detail_url.nil? || detail_url.empty? || store.nil?
    params_hash = CGI.parse(URI.parse(detail_url).query)
    if detail_url.start_with?("//item.taobao.com")
      detail_url = "http://world.taobao.com/item/#{params_hash.delete("id").first}.htm?#{URI.encode_www_form(params_hash.merge("fromSite"=> "main"))}"
    elsif detail_url.start_with?("//detail.tmall.com")
      detail_url = "http://world.tmall.com/item/#{params_hash.delete("id").first}.htm?#{URI.encode_www_form(params_hash)}"
    end

    response = Moonlight.request(detail_url, Moonlight::SHOP_HEADER).to_s
    desc_url = (match = response.match(/descUrl\s*:\s*"(\/\/)(.*?});/)) && match[2]
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
    response = Moonlight.request("https://shopsearch.taobao.com/search?app=shopsearch&q=%E5%A5%A2%E4%BE%88%E5%93%81%E4%BB%A3%E8%B4%AD&js=1&initiative_id=staobaoz_20160121&ie=utf8", Moonlight::PAGE_HEADER).to_s
    puts response
  end
end
Page.test

