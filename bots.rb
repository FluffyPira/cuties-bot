#!/usr/bin/env ruby
require 'twitter_ebooks'
include Ebooks
CONSUMER_KEY = ""
CONSUMER_SECRET = ""
OATH_TOKEN = "" # oauth token for ebooks account
OAUTH_TOKEN_SECRET = "" # oauth secret for ebooks account
ROBOT_ID = "ebooks" # Avoid infinite reply chains
TWITTER_USERNAME = "cuties_bot" # Ebooks account username
TEXT_MODEL_NAME = "cuties_bot" # This should be the name of the text model
DELAY = 2..30 # Simulated human reply delay range in seconds
BLACKLIST = ['insomnius', 'upulie', 'horse_inky', 'gray_noise', 'lookingglasssab', 'AmaznPhilEbooks', 'AKBAE_BOT'] # Grumpy users to avoid interaction with
SPECIAL_WORDS = ['bot', 'ebooks', 'cutie', 'cute', 'sexy', 'girl', 'boy', 'trans', 'queer', 'nb', 'binary', 'love']
# Track who we've randomly interacted with globally
$have_talked = {}
class GenBot
  
  def initialize(bot, modelname)
    @bot = bot
    bot.consumer_key = CONSUMER_KEY
    bot.consumer_secret = CONSUMER_SECRET

    bot.on_message do |dm|
      garbage = Random.new.bytes(5)
      bot.delay DELAY do
        bot.reply dm, "Talk to @FluffyPira #{garbage}"
      end 

    end 

    bot.on_follow do |user|
      bot.delay DELAY do
        bot.follow user[:screen_name]
      end 

    end 

    bot.on_mention do |tweet, meta|
      # Avoid infinite reply chains (very small chance of crosstalk)
      next if tweet[:user][:screen_name].include?(ROBOT_ID) && rand > 0.05
      next if tweet[:user][:screen_name].include?('bot') && rand > 0.20
      next if tweet[:user][:screen_name].include?('generateacat') && rand > 0.10
      tokens = NLP.tokenize(tweet[:text])
      special = tokens.find { |t| SPECIAL_WORDS.include?(t) }
      if special
        favorite(tweet) if rand < 0.5
      end 
      
    end 

    bot.on_timeline do |tweet, meta|
      next if BLACKLIST.include?(tweet[:user][:screen_name])
      next if $have_talked[tweet[:user][:screen_name]]

      tokens = NLP.tokenize(tweet[:text])
      special = tokens.find { |t| SPECIAL_WORDS.include?(t) }
      
      if special
        favorite(tweet) if rand < 0.5
        retweet(tweet) if rand < 0.1
        $have_talked[tweet[:user][:screen_name]] = true
      end 

    end 

    # Schedule a main tweet for every day at midnight
    bot.scheduler.every '1800' do
    
      sing = Dir.entries("pictures/") - %w[.. . .DS_Store]
  
      pic = sing.shuffle.pop
  
      bot.twitter.update_with_media("", File.new("pictures/#{pic}"))
      puts "@cutie_bot: pictures/#{pic}"    

    end 
    
    bot.scheduler.cron '0 0 * * *' do
      
      $have_talked = {}
    
    end

  end 

  def favorite(tweet)
    @bot.log "Favoriting @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    @bot.twitter.favorite(tweet[:id])

  end 

  def retweet(tweet)
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
