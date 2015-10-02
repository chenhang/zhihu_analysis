require 'mechanize'
class ZhihuPeople
  @base_url = 'http://www.zhihu.com/people/'

  attr_accessor :followers

  def initialize name, hash_id
    @name = name
    @hash_id = hash_id
    @followers = []
  end

  def agent
    @agent ||= Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
      agent.cookie_jar.load_cookiestxt('cookies.txt')
    end
  end

  def home_url
    @base_url+ @name
  end

  def followers_url offset=0
    "http://www.zhihu.com/node/ProfileFollowersListV2?method=next&params=%7B%22offset%22%3A#{offset}%2C%22order_by%22%3A%22created%22%2C%22hash_id%22%3A%22#{@hash_id}%22%7D&_xsrf=282a0ee06b92798c20be3c66378d1c5f"
  end

  def followers_links
    init_offset = 0
    while true
      follower_elements = agent.get(followers_url(init_offset)).search('.zm-list-content-title a')
      if follower_elements.nil? || follower_elements.empty?
        puts "#{@name} has followers: #{@followers.size}"
        break
      else
        follower_elements.each { |follower_element| @followers.push follower_element.attributes['href'].text }
        puts "#{@name}'s followers processed: #{init_offset}"
        init_offset+=20
      end
    end
  end
end

evenstar = ZhihuPeople.new('evenstar', 'ca946dc5bee68d0280d074b9925decf1')
evenstar.followers_links

xiepanda = ZhihuPeople.new('xiepanda', 'c948a6c96e21986af5d9c720334989f7')
xiepanda.followers_links

p (xiepanda.followers & evenstar.followers).size