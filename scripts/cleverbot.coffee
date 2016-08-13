# Description:
#   "Cleverbot"
#
# Dependencies:
#   "cleverbot-node": "0.1.1"
#
# Configuration:
#   None

cleverbot = require('cleverbot-node')

module.exports = (robot) ->
  c = new cleverbot()

  robot.respond /(.*)/i, (msg) ->
    data = msg.match[1].trim()
    cleverbot.prepare( =>
      c.write(data, (c) =>
        msg.send(msg.message.user.name + ": " + c.message)
        msg.finish()
      )
    )
