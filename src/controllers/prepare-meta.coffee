module.exports = (req, res, done) ->
  res.locals.meta = author: res.locals.participant._id
  done null
