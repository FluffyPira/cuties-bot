#!/usr/bin/env ruby
require 'twitter_ebooks'
require 'set'
include Ebooks

CONSUMER_KEY = ""
CONSUMER_SECRET = ""
OATH_TOKEN = "" # oauth token for ebooks account
OAUTH_TOKEN_SECRET = "" # oauth secret for ebooks account

TWITTER_USERNAME = "" # Ebooks account username
AUTHOR_NAME = "" # Put your twitter handle in here
DELAY = 2..30 # Simulated human reply delay range in seconds
BLACKLIST = [] # Grumpy users to avoid interaction with

SPECIAL_WORDS = ['your', 'words', 'here'] # may trigger fav
TRIGGER_WORDS = ['trigger', 'slur', 'shitty thing to say'] # will trigger auto block
# Thanks to @vex0rian and @parvitude for the random seed/post_pic method to keep it from posting duplicates near eachother.
# You are both cuties ~<3.
class GenBot
  
  def initialize(bot, modelname)
    @bot = bot
    bot.consumer_key = CONSUMER_KEY
    bot.consumer_secret = CONSUMER_SECRET
    
    bot.on_startup do
      @pics = Dir.entries("pictures/") - %w[.. . .DS_Store].sort
      bot.log @pics.take(5) # poll for consistency and tracking purposes.
      @status_count = @bot.twitter.user.statuses_count
      prune_following()
      post_picture()
    end

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
      tokens = NLP.tokenize(tweet[:text])
      special = tokens.find { |t| SPECIAL_WORDS.include?(t) }
      trigger = tokens.find { |t| TRIGGER_WORDS.include?(t) }
      
      if special
        favourite(tweet) if rand < 0.2
      elsif trigger
        block(tweet)
      end 

      
    end 

    bot.on_timeline do |tweet, meta|
      next if BLACKLIST.include?(tweet[:user][:screen_name])

      tokens = NLP.tokenize(tweet[:text])
      special = tokens.find { |t| SPECIAL_WORDS.include?(t) }
      trigger = tokens.find { |t| TRIGGER_WORDS.include?(t) }
      
      if special
        favourite(tweet) if rand < 0.1
      elsif trigger
        block(tweet) if rand < 0.2
      end 

    end 

    # Schedule a tweet for every 30 minutes
    bot.scheduler.every '3600' do
      post_picture()      
    end

  end 

  def favourite(tweet)
    @bot.log "Favoriting @#{tweet[:user][:screen_name]}: #{tweet[:text]}"
    @bot.twitter.favorite(tweet[:id])

  end 
 
  def next_index()
    seq = (0..(@pics.size - 1)).to_a
    seed = @status_count / @pics.size
    r = Random.new(seed)
    seq.shuffle!(random: r)
    res = seq[@status_count % @pics.size]
    @status_count = @status_count + 1
    return res
  end
 
  def post_picture()
    pic = @pics[next_index]
    @bot.twitter.update_with_media("", File.new("pictures/#{pic}"))
    @bot.log "posted pictures/#{pic}"
  end
  
  def prune_following()
    following = Set.new(@bot.twitter.friend_ids.to_a)
    followers = Set.new(@bot.twitter.follower_ids.to_a)
    to_unfollow = (following - followers).to_a
    @bot.log("Unfollowing user ids: #{to_unfollow}")
    @bot.twitter.unfollow(to_unfollow)
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
  make_bot(bot, TWITTER_USERNAME)
end