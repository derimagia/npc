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

  cleverbot.configure({botapi: process.env.CLEVERBOT_API_KEY});

  robot.respond /(.*)/i, (msg) ->
    data = msg.match[1].trim()
    cleverbot.prepare( =>
      c.write(data, (response) =>
        msg.send(msg.message.user.name + ": " + response.output)
        msg.finish()
      )
    )
