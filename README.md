# Cuties Bot v 0.3

A deployable twitter bot that solely exists to post pictures of cute things to the internet. Uses Mispy's [Twitter_Ebooks](https://github.com/mispy/twitter_ebooks) gem to run the bot, the script itself is based on Mispy's [Ebooks_example](https://github.com/mispy/ebooks_example) and modified to update with pictures only and none of the talky stuff.

## Usage:
To install and run the bot, simply insert the commands below.

- git clone https://github.com/FluffyPira/cuties-bot.git
- cd cuties-bot
- bundle install
- modify bots.rb to include oauth, account names, and author's twitter handle
- run with ./run.rb

Remember that to get the oauth information, you will need to create a [twitter app](https://apps.twitter.com/app/new) associated with the account or use [twurl](https://github.com/marcel/twurl) to associate your bot with an app. 

If you would prefer using different pictures, clear the "pictures" folder and move whatever pictures you want to post to twitter in there. They're posted automagically every 30 minutes unless otherwise specified.

## Heroku:
If you want to run the bot via heroku, there is a simple guide to deploying your [first git to heroku](https://devcenter.heroku.com/articles/git). If you already have heroku, the basic deployment prodecure is as follows:

- git clone https://github.com/FluffyPira/cuties-bot.git
- cd cuties-bot
- bundle install
- modify bots.rb to include oauth, account names, and author's twitter handle
- git init
- git add .
- git commit -m "_Your commit name_"
- heroku create
- heroku apps:rename "_Your app name_" 
- git push heroku master
- heroku ps:scale worker=1
