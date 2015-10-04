require 'mechanize'
require 'active_record'
require 'mysql2'
require 'logger'

ActiveRecord::Base.logger = Logger.new('debug.log')
configuration = YAML::load(IO.read('database.yml'))
ActiveRecord::Base.establish_connection(configuration['development'])

class User < ActiveRecord::Base
end

class ZhihuPeople
  @@base_url = 'http://www.zhihu.com/people/'

  attr_accessor :followers, :follower_urls

  def initialize name, hash_id
    name.include?(@@base_url) ?
        @home_url=name :
        @name=name
    @hash_id = hash_id
    self.follower_urls = []
    self.followers = {}
  end

  def agent
    @agent ||= Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
      agent.cookie_jar.load_cookiestxt('cookies.txt')
    end
  end

  def home
    @home ||= agent.get(home_url)
  end

  def home_url
    @home_url || (@@base_url + @name)
  end

  def business
    @business ||= (home.search('.business').first.attributes['title'].text rescue '')
  end

  def get_followers
    get_followers_urls
    self.followers = follower_urls.map { |url| [url, ZhihuPeople.new(url, '').business] }.to_h
  end

  def followers_url offset=0
    "http://www.zhihu.com/node/ProfileFollowersListV2?method=next&params=%7B%22offset%22%3A#{offset}%2C%22order_by%22%3A%22created%22%2C%22hash_id%22%3A%22#{@hash_id}%22%7D&_xsrf=282a0ee06b92798c20be3c66378d1c5f"
  end

  def get_followers_urls
    init_offset = 0
    while true
      follower_elements = agent.get(followers_url(init_offset)).search('.zm-list-content-title a')
      (follower_elements.nil? || follower_elements.empty?) ?
          break :
          follower_elements.each { |follower_element| self.follower_urls.push follower_element.attributes['href'].text }
      init_offset+=20
    end
    puts "#{@name} has followers: #{follower_urls.size}"
  end
end
begin
  evenstar = ZhihuPeople.new('evenstar', 'ca946dc5bee68d0280d074b9925decf1')
  evenstar.get_followers
  p evenstar.followers.group_by {|_, v| v}.map {|k, v| [k, v.size]}.sort_by(&:last).reverse.to_h
end


# xiepanda = ZhihuPeople.new('xiepanda', 'c948a6c96e21986af5d9c720334989f7')
# xiepanda.followers_links
