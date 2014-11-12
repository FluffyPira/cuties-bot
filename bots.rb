#!/usr/bin/env ruby
require 'twitter_ebooks'
include Ebooks
CONSUMER_KEY = ""
CONSUMER_SECRET = ""
OATH_TOKEN = "" # oauth token for ebooks account
OAUTH_TOKEN_SECRET = "" # oauth secret for ebooks account

ROBOT_ID = "book" # Avoid infinite reply chains
TWITTER_USERNAME = "" # Ebooks account username
TEXT_MODEL_NAME = "" # This should be the name of the text model
AUTHOR_NAME = "" # Put your twitter handle in here
DELAY = 2..30 # Simulated human reply delay range in seconds

BLACKLIST = ['insomnius', 'upulie'] # Grumpy users to avoid interaction with
SPECIAL_WORDS = ['bot', 'your', 'words', 'here']
TRIGGER_WORDS = ['cunt', 'bot', 'bitch', 'zoe', 'anita', 'tranny', 'shemale', 'faggot', 'fag', 'ethics in games journalism']

# Track who we've randomly interacted with globally
$have_talked = {}
class GenBot
  
  def initialize(bot, modelname)
    posted = Array.new
    @bot = bot
    bot.consumer_key = CONSUMER_KEY
    bot.consumer_secret = CONSUMER_SECRET

    bot.on_message do |dm|
      # We don't actually want the bot to really say anything, rather just post lots of cute pics.
      shit = Random.new.bytes(5)
      bot.delay DELAY do
        bot.reply dm, "Talk to #{AUTHOR_NAME} #{shit}" 
      end 

    end 

    bot.on_follow do |user|
      bot.delay DELAY do
        bot.follow user[:screen_name]
      end 

    end 

    bot.on_mention do |tweet, meta|
      # Avoid infinite reply chains (very small chance of crosstalk)
      # Probably unneeded as the bot no longer replies to folks, but still works at avoiding bot on bot interaction.
      # That stuff is sick, bot's just flaunting their robosexuality.
      # I'm not a robophobe, I swear!
      next if tweet[:user][:screen_name].include?(ROBOT_ID) && rand > 0.05
      next if tweet[:user][:screen_name].include?('bot') && rand > 0.20
      next if tweet[:user][:screen_name].include?('generateacat') && rand > 0.10
      
      tokens = NLP.tokenize(tweet[:text])
      special = tokens.find { |t| SPECIAL_WORDS.include?(t) }
      trigger = tokens.find { |t| TRIGGER_WORDS.include?(t.downcase) }
      
      if special
        favourite(tweet) if rand < 0.5
      elsif trigger
        block(tweet)
      end 
      
    end 

    bot.on_timeline do |tweet, meta|
      next if BLACKLIST.include?(tweet[:user][:screen_name])
      next if $have_talked[tweet[:user][:screen_name]]

      tokens = NLP.tokenize(tweet[:text])
      special = tokens.find { |t| SPECIAL_WORDS.include?(t) }
      trigger = tokens.find { |t| TRIGGER_WORDS.include?(t.downcase) }
      
      if special
        favourite(tweet) if rand < 0.5
        retweet(tweet) if rand < 0.1
        $have_talked[tweet[:user][:screen_name]] = true
        # If a trigger word is mentioned by someone they're following, chance to block user.
      elsif trigger
        block(tweet) if rand < 0.2
      end 

    end 

    # Schedule a tweet for every 30 minutes
    bot.scheduler.every '1800' do
      
      piclist = get_pics(posted) 

      if piclist.empty?
        posted.clear
        piclist = get_pics(posted) 
      end
      
      pic = piclist.shuffle.pop
        
      bot.twitter.update_with_media("", File.new("pictures/#{pic}"))
      bot.log "#{TWITTER_USERNAME}: pictures/#{pic}"
      posted.push(pic)
      # Debug stuff. Uncomment it if you want this to show up in the log as well.
      # bot.log "#{TWITTER_USERNAME}: Total pics posted: #{posted.size}, Total pics remaining #{piclist.size}"  
      
    end

    
    # Schedule clearance of the $have_talked list every day at midnight.
    bot.scheduler.cron '0 0 * * *' do
      
      $have_talked = {}
    
    end

  end 

  def favourite(tweet)
    @bot.log "Favoriting @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    @bot.twitter.favorite(tweet[:id])

  end 

  def retweet(tweet)
    @bot.log "Retweeting @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    @bot.delay DELAY do
      @bot.twitter.retweet(tweet[:id])
    end 

  end 
  
  def get_pics(posted)    
    pics = Dir.entries("pictures/") - %w[.. . .DS_Store]
    pics -= posted
    pics      
  end
  
  def block(tweet)
    @bot.log "Blocking and reporting @#{tweet[:user][:screen_name]}"
    @bot.twitter.block(tweet[:user][:screen_name])
    @bot.twitter.report_spam(tweet[:user][:screen_name])
  end

end 

def make_bot(bot, modelname)
  GenBot.new(bot, modelname)
end 

Ebooks::Bot.new(TWITTER_USERNAME) do |bot|
  bot.oauth_token = OATH_TOKEN
  bot.oauth_token_secret = OAUTH_TOKEN_SECRET
  make_bot(bot, TEXT_MODEL_NAME)
end 