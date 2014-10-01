#!/usr/bin/env ruby
require 'twitter_ebooks'
include Ebooks
CONSUMER_KEY = ""
CONSUMER_SECRET = ""
OATH_TOKEN = "" # oauth token for ebooks account
OAUTH_TOKEN_SECRET = "" # oauth secret for ebooks account
ROBOT_ID = "ebooks" # Avoid infinite reply chains
TWITTER_USERNAME = "cuties_bot" # Ebooks account username
TEXT_MODEL_NAME = "transcloudie" # This should be the name of the text model
DELAY = 2..30 # Simulated human reply delay range in seconds
BLACKLIST = ['insomnius', 'upulie', 'horse_inky', 'gray_noise', 'lookingglasssab', 'AmaznPhilEbooks', 'AKBAE_BOT'] # Grumpy users to avoid interaction with
SPECIAL_WORDS = ['bot', 'ebooks', 'cutie', 'cute', 'sexy', 'girl', 'boy', 'trans', 'queer', 'nb', 'binary', 'love']
# Track who we've randomly interacted with globally
$have_talked = {}
class GenBot
  
  def initialize(bot, modelname)
    @bot = bot
    @model = nil
    bot.consumer_key = CONSUMER_KEY
    bot.consumer_secret = CONSUMER_SECRET
    bot.on_startup do
      @model = Model.load("model/#{modelname}.model")
      @top100 = @model.keywords.top(100).map(&:to_s).map(&:downcase)
      @top50 = @model.keywords.top(20).map(&:to_s).map(&:downcase)
    end 

    bot.on_message do |dm|
      bot.delay DELAY do
        bot.reply dm, @model.make_response(dm[:text])
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
      very_interesting = tokens.find_all { |t| @top50.include?(t.downcase) }.length > 2
      special = tokens.find { |t| SPECIAL_WORDS.include?(t) }
      if very_interesting || special
        favorite(tweet)
      end 

      reply(tweet, meta)
    end 

    bot.on_timeline do |tweet, meta|
      next if tweet[:retweeted_status] || tweet[:text].start_with?('RT')
      next if BLACKLIST.include?(tweet[:user][:screen_name])
      tokens = NLP.tokenize(tweet[:text])
      # We calculate unprompted interaction probability by how well a
      # tweet matches our keywords
      interesting = tokens.find { |t| @top100.include?(t.downcase) }
      very_interesting = tokens.find_all { |t| @top50.include?(t.downcase) }.length > 2
      special = tokens.find { |t| SPECIAL_WORDS.include?(t) }
      if special
        favorite(tweet) if rand < 0.5
        favd = true # Mark this tweet as favorited
      end 

      # Any given user will receive at most one random interaction per day
      # (barring special cases)
      next if $have_talked[tweet[:user][:screen_name]]
      $have_talked[tweet[:user][:screen_name]] = true
      if very_interesting || special
        favorite(tweet) if (rand < 0.3 && !favd) # Don't fav the tweet if we did earlier
        reply(tweet, meta) if rand < 0.1
      elsif interesting
        favorite(tweet) if rand < 0.3
        reply(tweet, meta) if rand < 0.1
      end 

    end 

    # Schedule a main tweet for every day at midnight
    bot.scheduler.every '1800' do
      
      pictweet = @model.make_statement
    
      sing = Dir.entries("pictures/") - %w[.. . .DS_Store]
  
      pic = sing.shuffle.pop
  
      if rand < 0.75
        bot.twitter.update_with_media("", File.new("pictures/#{pic}"))
        puts "@cutie_bot: #{pictweet} + pictures/#{pic}"  
        $have_talked = {}      
      else
        bot.twitter.update("#{pictweet}")
        puts "@cutie_bot: #{pictweet}" 
        $have_talked = {} 
      end 

    end 

  end 

  def reply(tweet, meta)
    resp = @model.make_response(meta[:mentionless], meta[:limit])
    @bot.delay DELAY do
      @bot.reply tweet, meta[:reply_prefix] + resp
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
