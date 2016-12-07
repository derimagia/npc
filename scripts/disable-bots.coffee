# Description:
#   "Middleware to disable responding to bots"

module.exports = (robot) ->
  robot.receiveMiddleware (context, next, done) ->
    if context.response.message.user.is_bot || context.response.message.user.name == "rss"
      done()
    else
      next(done)
