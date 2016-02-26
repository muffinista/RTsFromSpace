#!/usr/bin/env ruby

require 'rubygems'
require 'chatterbot/dsl'

# remove this to get less output when running
verbose


# ID of the list this bot has of spacey accounts
LIST_ID=176604393

# only look at tweets from the last hour
TIME_RANGE=3600

# min count of RTs/favs required for the bot to RT
RT_THRESHOLD=25
FAV_THRESHOLD=70


# NASA tweets get a lot of RTs and Favs so we hold them to a higher standard
SPECIAL_THRESHOLDS = {
  "nasa" => [250, 500]
}


#
# this commented code is used to follow accounts and also add them to
# a list. following accounts is important because it reduces the
# chances that twitter treats the bot as a spammer
#
#

# members = ["ObservingSpace", "nasahqphoto", "AsteroidWatch", "apod", "NASALADEE", "NASAGoddard", "NASA_Hubble", "CassiniSaturn", "AsteroidWatch", "NASAJPL", "MarsRovers", "NASAWebbTelescp", "CassiniSaturn", "ESA", "NewHorizons2015", "NASA_Johnson", "NASAGoddard", "ISS_Research", "chandraxray", "HUBBLE_space", "nasahqphoto", "SpaceX", "dsn_status", "NASANewHorizons", "OSIRISREx"]
# client.add_list_members(LIST_ID, members)

# friends = client.friend_ids

# client.list_members(LIST_ID).to_a.each { |u|
#   puts u.inspect
#   follow u unless friends.include? u.id
# }

#puts "done following!"

def over_rt_threshold?(t)
  name = t.user.screen_name.downcase
  rt_count = SPECIAL_THRESHOLDS[name] && SPECIAL_THRESHOLDS[name].first
  rt_count ||= RT_THRESHOLD

  t.retweet_count > rt_count  
end

def over_fav_threshold?(t)
  name = t.user.screen_name.downcase
  fav_count = SPECIAL_THRESHOLDS[name] && SPECIAL_THRESHOLDS[name].last
  fav_count ||= FAV_THRESHOLD

  t.favorite_count > fav_count  
end

# keep track of a list of tweets that we have retweeted already so we
# don't spam the Twitter API
bot.config[:rts] ||= []


my_retweets = bot.config[:rts] || []

# even though the bot is following all the accounts we want to RT, I
# check against the list timeline other than the bot's actual timeline
# in case it ever follows someone that I don't want to RT
client.list_timeline(LIST_ID).take(444400).each { |t|
  # we only want to tweet original tweets to keep signal v noise high
  # this skips tweets of other accounts that accounts in our list RT'd
  next if t.retweet?
  
  if ( over_rt_threshold?(t) || over_fav_threshold?(t) ) && ! my_retweets.include?(t.id)
    puts "#{t.text} #{t.retweet_count}  #{t.favorite_count}"
    begin 
      my_retweets << t.id
      retweet t
    rescue StandardError => e
      puts e.inspect
    end
  end
}

# store list of RTs
bot.config[:rts] = my_retweets

# but no need to store more than a 100 or so
if bot.config[:rts].length > 100
  bot.config[:rts] = bot.config[:rts][-100..-1]
end

update_config
