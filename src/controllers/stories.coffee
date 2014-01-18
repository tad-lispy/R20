# # Story controller

# Models
Story       = require "../models/Story"
Question    = require "../models/Question"
Answer      = require "../models/Answer"
Participant = require "../models/Participant"

# Controller
Controller  = require "./ModelController"

# Helpers
pre   =
  meta      : require "./prepare-meta"
  conditions: require "./prepare-conditions"
post  =
  draft     : require "./post-draft"
async       = require "async"
debug       = require "debug"
$           = debug   "R20:controllers:story"

module.exports = new Controller Story,
  routes:
    list            : options: pre  : pre.conditions

    new             : options: pre  : pre.meta

    single          : options:
      pre  : pre.conditions
      post : (req, res, done) ->
        { story } = res.locals
        $ "Populate questions"
        async.parallel [
          (done) -> 
            async.series [
              (done) -> story.populate "questions", done
              (done) -> async.each story.questions,
                (question, done) ->
                  question.findAnswers (error, answers) ->
                    if error then return done error
                    Participant.populate answers, "author", (error) ->
                      if error then return done error
                      question.answers = answers
                      done null
                 done
            ], done

          # Populate journal meta
          (done) ->
            Participant.populate res.locals.journal,
              path: "meta.author"
              done
        ], done
      
    draft           : options: post: post.draft

    apply           : options: pre: pre.meta
    save            : options: pre: pre.meta
    remove          : options: pre: pre.meta
    questions_add   : options: pre: pre.meta
    questions_delete: options: pre: pre.meta




  # list:
  #   prepareConditions: (req, res, done) ->
  #     if req.query.query? 
  #       conditions = text: 
  #       res.locals query: req.query.query
  #     done null, conditions
  # new:
  #   fields: [
  #     "text"
  #   ]
  #   prepareMeta: (req, res, done) -> done null,
  #     author: res.locals.participant._id

  # single:
  #   transformation: (story, done) ->
  #     # Find related questions
  #     story.populate "questions", (error, story) ->
  #       if error then return done error
  #       $ "After population the story is: %j", story
  #       done null, story

  #   journal_transformation: (entries, done) ->
  #     Participant.populate entries,
  #       path: "meta.author"
  #       done

  # single_draft:
  #   transformation: (draft, done) ->
  #     # populate author
  #     draft.populate
  #       path  : "meta.author"
  #       model : "Participant"
  #       (error, draft) ->
  #         if error then return done error
  #         $ "After population the draft is: %j", draft
  #         done null, draft

  #   populate:
  #     path  : "meta.author"
  #     model : "Participant"
