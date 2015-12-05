# Description:
#   Broadcasts and Monitors user in the Mumble Server
#
# Commands:
#   !mumble List all people connected to mumble

Util = require "util"

module.exports = (robot) ->
  userlist = []

  updateMumble = (callback) ->
    callback = callback || ->

    robot.http('http://commsviewer.com/api/commsviewer.php?cvserverid=3691&callback=')
    .header('Accept', 'application/json')
    .get() (err, res, body) ->
      startPos = body.indexOf('({')
      endPos = body.indexOf('})')
      jsonString = body.substring(startPos+1, endPos+1)
      data = JSON.parse(jsonString)
      currentusers = recurseTree(data.root)

      newusers = diffUsers(currentusers, userlist)
      leftusers = diffUsers(userlist, currentusers)

      if process.env.MUMBLE_BROADCAST_ROOM?
        room = process.env.MUMBLE_BROADCAST_ROOM

        if newusers.length > 0
          newusernames = (user.name for user in newusers).join(', ')
          robot.messageRoom room, "#{newusernames} has joined the Mumble Server."

        if leftusers.length > 0
          leftusernames = (user.name for user in leftusers).join(', ')
          robot.messageRoom room, "#{leftusernames} has left the Mumble Server."

      userlist = currentusers
      callback()

  diffUsers = (arr1, arr2) ->
    arr1.filter ((user1) ->
      return !arr2.some((user2) -> \
        return user1.name == user2.name
      )
    )

  recurseTree = (tree) ->
    users = tree.users

    for channel in tree.channels
      users = users.concat(recurseTree(channel))

    return users

  robot.hear /^!mumble/i, (msg) ->
    updateMumble(->
      users = (user.name for user in userlist).join(', ')
      msg.send "The following people are in mumble: #{users}"
    )

  setInterval () ->
    updateMumble()
  , 60000

