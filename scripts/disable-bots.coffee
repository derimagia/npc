# Description:
#   "Middleware to disable responding to bots"

module.exports = (robot) ->
  robot.receiveMiddleware (context, next, done) ->
    if context.response.message.user.is_bot?
      done()
    else
      next(done)