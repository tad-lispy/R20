# Question controller

async     = require "async"
_         = require "underscore"

debug     = require "debug"

$         = debug "R20:controllers:question"

Story     = require "../models/Story"
Question  = require "../models/Question"
Entry     = require "../models/JournalEntry"

module.exports = 
  # General
  get    : (req, res) ->
    # Get a list of all questions
    if req.query.query? 
      conditions = text: new RegExp req.query.query, "i"
      res.locals query: req.query.query

    Question.find conditions, (error, questions) ->
      if error then throw error
      if (req.accepts ["json", "html"]) is "json"
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
      async.waterfall [
        (done) ->
          Question.findByIdOrCreate req.params.id,
            text: "**VIRTUAL**: this question is not saved. Some drafts for it exists though."
            (error, question) ->
              if error then return done error
              done null, question

        (question, done) ->
          question.findStories (error, stories) ->
            if error then return done error
            done null, question, stories

      ], (error, question, stories) ->
          if error then throw error
          if (req.accepts ["json", "html"]) is "json"
            res.json { question, stories }
          else
            template = require "../views/question"
            res.locals { question, stories }
            res.send template.call res.locals

    draft:
      ":draft_id":
        get: (req, res) ->
          $ = $.root.narrow "single:draft:single"

          async.waterfall [
            (done) ->
              $ = $.narrow "find_draft"
              Entry.findById req.params.draft_id, (error, entry) ->
                if error then throw error
                if not entry or
                  entry.action isnt "draft" or
                  not entry.data?._id?.equals req.params.id 
                    return done error "Not found"

                return done null, entry

            (draft, done) ->
              $ = $.narrow "find_or_create_question"
              Question.findByIdOrCreate draft.data._id,
                text: "**VIRTUAL**: this question is not saved. Some drafts for it exists though."
                (error, question) ->
                  if error then return done error
                  done null, draft, question

            (draft, question, done) ->
              $ = $.narrow "find_other_drafts"
              question.findEntries action: "draft", (error, drafts) ->
                if error then return done error

                done null, draft, question, drafts

          ], (error, draft, question, drafts) ->
            $ = $.narrow "send"
            if error
              if error.message is "Not found"
                if (req.accepts ["json", "html"]) is "json"
                  return res.json 404, error: 404
                else
                  return res.send 404, "I'm sorry, I can't find this draft."
              else # different error
                throw error 
            
            if (req.accepts ["json", "html"]) is "json"
              res.json draft
            else 
              res.locals { draft, question, journal: drafts }

              $ "Sending ", { draft, question, journal: drafts }

              template = require "../views/question"
              res.send template.call res.locals




