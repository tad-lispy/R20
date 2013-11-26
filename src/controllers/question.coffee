# Question controller

async     = require "async"
_         = require "underscore"

debug     = require "debug"

$         = debug "R20:controllers:question"

Story     = require "../models/Story"
Question  = require "../models/Question"
Entry     = require "../models/JournalEntry"


# TODO: DRY! It's almost the same as story controller, and as answers and participant will be.
# IDEA: Controller class
#   Constructor takes a model and options
#   returns something like below!
# 
#   So in the end you get:
#   module.exports = Controller Story, options

class Controller
  constructor: (@_model, @_options = {}) ->

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
    get : (req, res) ->
      # Get a single question
      $ = $.root.narrow "single"

      async.waterfall [
        (done) ->
          # Find a question or make a virtual
          $ = $.narrow "find_question"

          # if req.query.query?
          #   conditions = text: new RegExp req.query.query, "i"
          #   res.locals query: req.query.query


          Question.findByIdOrCreate req.params.id,
            text: "**VIRTUAL**: this question is not saved. Some drafts for it exists though."
            (error, question) ->
              if error then return done error
              done null, question
              
        (question, done) -> 
          # Find related stories
          if question.isNew then done null, question, []
          else question.findStories (error, stories) ->
            if error then return done error
            done null, question, stories

        (question, stories, done) -> 
          # Find journal entries
          $ = $.narrow "find_journal_entries"

          question.findEntries (error, entries) ->
            if error then return done error
            if not entries.length and question.isNew then return done Error "Not found"

            done null, question, stories, entries

      ], (error, question, stories, journal) ->
        # Send results
        $ = $.narrow "send"

        if error
          if error.message is "Not found"
            $ "Not found (no question and no drafts)"
            if (req.accepts ["json", "html"]) is "json"
              return res.json 404, error: 404
            else
              return res.send 404, "I'm sorry, I don't know this question."

          else # different error
            throw error 

        if (req.accepts ["json", "html"]) is "json"
          res.json question
        else
          res.locals { question, stories, journal }
          template = require "../views/question"
          res.send template.call res.locals


    put: (req, res) ->
      # Apply a draft or save a new draft
      $ = $.root.narrow "update"

      if req.body._draft? 
        $ "Applying draft %s to question %s", req.body._draft, req.params.id
        
        async.waterfall [
          (done) ->
            # Find a draft
            $ = $.narrow "find_draft"

            Entry.findById req.body._draft, (error, draft) ->
              if error then return done error
              if not draft then return done Error "Draft not found"
              if not draft.data._id.equals req.params.id 
                $ "Draft %j doesn't match question %s", draft, req.params.id
                return done Error "Draft doesn't match document"
              done null, draft

          (draft, done) ->
            # Apply draft
            draft.apply author: req.session.email, (error, question) ->
              if error then return done error
              done null, question
        ], (error, question) ->
            if error
              $ "There was en error: %s", error.message
              switch error.message
                when "Draft not found"
                  if (req.accepts ["json", "html"]) is "json"
                    return req.json 409, error: "Draft #{req.body.draft} not found."
                  else
                    return res.send 409, "Draft #{req.body.draft} not found."
                
                when "Draft doesn't match document"
                  if (req.accepts ["json", "html"]) is "json"
                    return req.json 409, error: "Draft #{req.body._draft} doesn't match question #{req.params.id}."
                  else
                    return res.send 409, "Draft #{req.body._draft} doesn't match question #{req.params.id}."
                
                else throw error # different error

            $ "Draft applied"
            if (req.accepts ["json", "html"]) is "json" then req.json question.toJSON()
            else res.redirect "/question/#{question._id}"
      
      # Save a new draft
      else async.waterfall [
        (done) ->
          Question.findByIdOrCreate req.params.id,
            text: "**VIRTUAL**: this question is not saved. Some drafts for it exists though."
            (error, question) ->
              if error then return done error
              _(question).extend _(req.body).pick [
                "text"
              ]
              done null, question

        (question, done) ->
          question.saveDraft author: req.session.email, (error, draft) ->
            $ = $.narrow "save_draft"
            if error then throw error
            done null, draft
        ], (error, draft) ->
          if error then throw error

          if (req.accepts ["json", "html"]) is "json"
            res.json draft.toJSON()
          else
            res.redirect "/question/#{req.params.id}/draft/#{draft._id}"


    draft:
      ":draft_id":
        get: (req, res) ->
          $ = $.root.narrow "single:draft:single"

          async.waterfall [
            (done) ->
              $ = $.narrow "find_draft"
              Entry.findById req.params.draft_id, (error, entry) ->
                if error then throw error
                if (not entry) or
                   (entry.action  isnt "draft") or
                   (entry.model   isnt "Question") or
                    not (entry.data?._id?.equals req.params.id)
                      return done Error "Not found"

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

c = new Controller Question
console.log "Controller is a %s: %j", typeof c, c
module.exports = c

