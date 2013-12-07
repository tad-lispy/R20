# Question controller

debug       = require "debug"
$           = debug "R20:controllers:question"

Question    = require "../models/Question"
Story       = require "../models/Question"
Participant = require "../models/Participant"

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
      author: res.locals.participant._id

  single:
    other_documents: (question, done) ->
      $ "Looking for story with question %s", question._id
      question.findStories (error, stories) -> done error, { stories }
    journal_transformation: (entries, done) ->
      Participant.populate entries,
        path: "meta.author"
        done


  single_draft:
    # populate author
    transformation: (draft, done) ->
      draft.populate
        path  : "meta.author"
        model : "Participant"
        (error, draft) ->
          if error then return done error
          $ "After population the draft is: %j", draft
          done null, draft

