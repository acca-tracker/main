
require_relative 'text-add-bet.rb'

require 'rubygems'
require 'highline/import'
require 'mechanize'
require 'nokogiri'

def local_body
  f = File.open("inspect.html")
  f.read
end

def get_username
  print "Username: "
  $stdin.gets.strip
end

def get_pin
  ask("Password: ") {|q| q.echo = false}
end

class AutoGetBets

  def initialize
    parse_body_to_bets(login_and_get_open_bets)
#    parse_body_to_bets(local_body)
  end

  def login_and_get_open_bets
    username = get_username
    pin = get_pin

    mech_agent = Mechanize.new { | agent |
      agent.follow_meta_refresh = true
    }
    mech_agent.get("http://www.skybet.com/skybet?action=GoStatic") do | home_page |
      user_home = home_page.form_with(:name => nil) do | form |
        form.uname = username
        form.pword = pin
      end.submit
      bet_page = mech_agent.click(user_home.link_with(:text => /Unsettled Bets/))
      return bet_page.body
    end
  end

  def parse_body_to_bets(raw_body)
    body = Nokogiri::HTML::DocumentFragment.parse(raw_body)
    body.css('tr').map do | row |
      data = row.xpath('./td').map(&:text)[4]
      next unless data
      data.gsub!("\t", "")
      str = ""
      data.each_line { | line |
        next if line == "\n"
        str += line.strip
        str += "\n"
      }
      begin
        TextAddBet.new.parse_from_str(get_name, str)
      rescue FailedToParseException => e
        puts e.message
        puts "Moving to next bet, if one exists..."
      end
    end
  end

end
