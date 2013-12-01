# # Story controller

Story       = require "../models/Story"
Question    = require "../models/Question"
Controller  = require "./Controller"

debug       = require "debug"
$           = debug "R20:controllers:story"

module.exports = new Controller Story,
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
    transformation: (story, done) ->
      # Find related questions
      story.populate "questions", (error, story) ->
        if error then return done error
        $ "After population the story is: %j", story
        done null, story

  single_draft:
    transformation: (draft, done) ->
      # populate author
      draft.populate
        path  : "meta.author"
        model : "Participant"
        (error, draft) ->
          if error then return done error
          $ "After population the draft is: %j", draft
          done null, draft

    populate:
      path  : "meta.author"
      model : "Participant"
