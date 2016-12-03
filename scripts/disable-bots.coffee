# Description:
#   "Middleware to disable responding to bots"

module.exports = (robot) ->
  robot.receiveMiddleware (context, next, done) ->
    console.log(context.response.message.user)
    if context.response.message.user.is_bot || context.response.message.user.name == ""
      done()
    else
      next(done)
