# Question controller

debug       = require "debug"
$           = debug "R20:controllers:question"

Question    = require "../models/Question"

Controller  = require "./Controller"

module.exports = new Controller Question,
  list:
    prepareConditions: (req, res, done) ->
      if req.query.query? 
        conditions = text: new RegExp req.query.query, "i"
        res.locals query: req.query.query
      done null, conditions

  new:
    fields: [
      "text"
    ]
    prepareMeta: (req, res, done) -> done null,
      author: req.session.email

  single:
    getAdditionalDocuments: (question, done) ->
      # Find related stories
      if question.isNew then done null, question, []
      else question.findStories (error, stories) ->
        if error then return done error
        done null, { stories }

