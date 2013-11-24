# Question controller

async     = require "async"
_         = require "underscore"

debug     = require "debug"

$         = debug "R20:controllers:question"

Story     = require "../models/Story"
Question  = require "../models/Question"

module.exports = 
  # General
  get    : (req, res) ->
    # Get a list of all questions
    if req.query.query? 
      query = text: new RegExp req.query.query, "i"
      res.locals query: req.query.query

    Question.find query, (error, questions) ->
      if error then throw error
      if (req.accepts ["json", "html"]) is "json"
        console.log req.url
        res.json questions
      else
        template = require "../views/questions"
        res.locals { questions }
        res.send template.call res.locals


  post: (req, res) ->
    # New story
    $ = $.root.narrow "new"

    question = new Question _.pick req.body, ["text"]
    question.saveDraft
      author: req.session.email
      (error, entry) ->
        $ = $.narrow "draft_saved"
        if error then throw error
        
        if (req.accepts ["json", "html"]) is "json"
          res.json entry.toJSON()
        else
          res.redirect "/question/#{question._id}/draft/#{entry._id}"

  ":id" :
    # Single question
    get : (req, res) ->
      async.parallel
        question: (done) ->
          Question.findById(req.params.id)
            .exec (error, question) ->
              if error then return done error
              question.findStories (error, stories) ->
                if error then return done error
                done null, _.extend question.toObject(), { stories }
        
        suggestions: (done) ->
          Question.find (error, questions) ->
            if error then return done error
            done null, { questions }

        (error, data) ->
          if error then throw error
          console.dir data
          if (req.accepts ["json", "html"]) is "json"
            res.json data
          else
            template = require "../views/question"
            res.locals data
            res.send template.call res.locals


