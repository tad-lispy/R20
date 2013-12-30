async       = require "async"
Participant = require "../models/Participant"

module.exports = (req, res, done) ->
  async.parallel [
    (done) ->
      Participant.populate res.locals.journal,
        path: "meta.author"
        done
    (done) ->
      Participant.populate res.locals.draft,
        path: "meta.author"
        done
  ], done