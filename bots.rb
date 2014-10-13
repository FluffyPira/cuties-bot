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
# Track who we've randomly interacted with globally
$have_talked = {}
class GenBot
  
  def initialize(bot, modelname)
    @bot = 👽 = bot
    👽.consumer_key = CONSUMER_KEY
    👽.consumer_secret = CONSUMER_SECRET

    👽.on_message do |dm|
      # We don't actually want the bot to really say anything, rather just post lots of cute pics.
      💩 = Random.new.bytes(5)
      👽.delay DELAY do
        👽.reply dm, "Talk to #{AUTHOR_NAME} #{💩}" 
      end 

    end 

    👽.on_follow do |user|
      👽.delay DELAY do
        👽.follow user[:screen_name]
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
      🃏 = NLP.tokenize(tweet[:text])
      🌟 = 🃏.find { |t| SPECIAL_WORDS.include?(t) }
      if 🌟
        🆗(tweet) if rand < 0.5
      end 
      
    end 

    bot.on_timeline do |tweet, meta|
      next if BLACKLIST.include?(tweet[:user][:screen_name])
      next if $have_talked[tweet[:user][:screen_name]]

      🃏 = NLP.tokenize(tweet[:text])
      🌟 = 🃏.find { |t| SPECIAL_WORDS.include?(t) }
      
      if 🌟
        🆗(tweet) if rand < 0.5
        🔁(tweet) if rand < 0.1
        $have_talked[tweet[:user][:screen_name]] = true
      end 

    end 

    # Schedule a tweet for every 30 minutes
    👽.scheduler.every '1800' do
    
      🐈 = Dir.entries("pictures/") - %w[.. . .DS_Store]
  
      🐆 = 🐈.shuffle.pop
      
      # An easier method of doing this without having to echo to log would be "pictures/#{🐈.shuffle.pop}"
      # If you chose that method, eliminate the second variable (🐆) and "puts"
  
      👽.twitter.update_with_media("", File.new("pictures/#{🐆}"))
      puts "@cutie_bot: pictures/#{🐆}"    

    end 
    
    # Schedule clearance of the $have_talked list every day at midnight.
    bot.scheduler.cron '0 0 * * *' do
      
      $have_talked = {}
    
    end

  end 

  def 🆗(tweet)
    @bot.log "Favoriting @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    @bot.twitter.favorite(tweet[:id])

  end 

  def 🔁(tweet)
    @bot.log "Retweeting @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    @bot.delay DELAY do
      @bot.twitter.retweet(tweet[:id])
    end 

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
