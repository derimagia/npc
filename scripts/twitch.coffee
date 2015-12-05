# Description:
#   Messing around with the Twitch API
#
# Commands:
#   !twitchadd <broadcaster> <type> - Adds a broadcaster to monitor
#   !twitchremove <broadcaster> - Stop monitoring a broadcasters
#   !twitchlist - List all broadcasters
#   !<twitchname> - List all broadcasters and stream status. Matches regex.

Util = require "util"

module.exports = (robot) ->
  broadcasterList =
    setBroadcasters:(broadcasters) ->
      robot.brain.set 'broadcasters', broadcasters
      robot.brain.save

    add:(broadcaster) ->
      broadcasters = @getAll()

      if broadcaster of broadcasters
        return false

      broadcasters[broadcaster] = {}
      @setBroadcasters broadcasters
      return true

    remove:(broadcaster) ->
      broadcasters = @getAll()

      unless broadcaster of broadcasters
        return false

      delete broadcasters[broadcaster]
      @setBroadcasters broadcasters
      return true

    get:(broadcaster) ->
      broadcasters = @getAll()
      return broadcasters[broadcaster] or {}

    getAll: ->
      return robot.brain.get('broadcasters') or {}

    fetch: ->
      broadcasters = @getAll()
      for name of broadcasters
        broadcaster = @get(name)
        delete broadcaster.previous
        broadcaster.previous = Util._extend({}, broadcaster)
        broadcaster.live = false

      @setBroadcasters(broadcasters)
      @fetchTwitch()

    fetchTwitch:(broadcaster_name) ->
      self = this

      broadcaster_name = broadcaster_name or (name for name of @getAll()).join(',')
      robot.http('https://api.twitch.tv/kraken/streams?channel=' + broadcaster_name)
      .header('Accept', 'application/json')
      .get() (err, res, body) ->
        data = JSON.parse(body)

        if data.streams?
          for stream in data.streams
            channel = stream['channel']
            login = channel['name']
            broadcaster = self.get(login)
            hasPrevious = broadcaster.previous? && broadcaster.previous.lastlive?
            broadcaster.justLive = !hasPrevious || (!broadcaster.previous.live && (Date.now() > broadcaster.lastlive + (60000*5)))
            broadcaster.switchedGames = !broadcaster.justLive and broadcaster.game != stream['game']
            broadcaster.live = true
            broadcaster.name = login
            broadcaster.game = stream['game']
            broadcaster.title = channel['status']
            broadcaster.viewers = stream['viewers']
            broadcaster.liveurl = channel['url']
            broadcaster.service = 'twitch'
            broadcaster.lastlive = Date.now()
            info = {'justLive' : broadcaster.justLive, 'switchedGames' : broadcaster.switchedGames}
            broadcasterList.updateBroadcaster(broadcaster, info)

    updateBroadcaster:(broadcaster, info) ->
      if process.env.LIVESTREAM_BROADCAST_ROOM?
        room = process.env.LIVESTREAM_BROADCAST_ROOM

        if info.justLive
          robot.messageRoom room, "#{broadcaster.name} just went live and is playing #{broadcaster.game}. \"#{broadcaster.title}\" - #{broadcaster.viewers} Viewers - #{broadcaster.liveurl}"
        else if info.switchedGames
          robot.messageRoom room, "#{broadcaster.name} just switched games and is playing #{broadcaster.game}. \"#{broadcaster.title}\" - #{broadcaster.viewers} Viewers - #{broadcaster.liveurl}"

      # Update the brain
      broadcasters = broadcasterList.getAll()
      broadcasters[broadcaster.name] = broadcaster
      broadcasterList.setBroadcasters(broadcasters)


  robot.hear /^!twitchadd (\S+)(?: (\S+))?/i, (msg) ->
    broadcaster = msg.match[1].trim().toLowerCase()

    if broadcasterList.add(broadcaster)
      msg.send "Ok, I will now start monitoring #{broadcaster}"
    else
      msg.send "No, I am already monitoring #{broadcaster}!"
    msg.finish()

  robot.hear /^!twitchlist/i, (msg) ->
    broadcasters_string = (name for name of broadcasterList.getAll()).join(', ')
    msg.send "I am monitoring: #{broadcasters_string}"
    msg.finish()

  robot.hear /^!twitchremove (\S+)/i, (msg) ->
    broadcaster = msg.match[1].trim().toLowerCase()

    if broadcasterList.remove(broadcaster)
      msg.send "I will no longer monitor #{broadcaster}"
    else
      msg.send "No, I am not monitoring #{broadcaster}!"
    msg.finish()

  robot.hear /^!(\S+)/i, (msg) ->
    match = msg.match[1].trim()

    wildcard = match == '*'
    match = '.*' if wildcard

    regex = new RegExp("#{match}", "i")

    broadcasters = broadcasterList.getAll()
    for name of broadcasters
      if regex.test(name)
        broadcaster = broadcasters[name]
        if broadcaster.name and broadcaster.live
          msg.send "#{broadcaster.name} is live and is playing #{broadcaster.game}. \"#{broadcaster.title}\" - #{broadcaster.viewers} Viewers - #{broadcaster.liveurl}"

        if !broadcaster.live and !wildcard
          lastlive =  if broadcaster.lastlive then new Date(broadcaster.lastlive).toISOString() else "Never"
          msg.send "#{name} is not live. Last Live: #{lastlive}"

    broadcasterList.fetch()

  setInterval () ->
    broadcasterList.fetch()
  , 60000

