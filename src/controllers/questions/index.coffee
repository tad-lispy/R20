# Question controller
async       = require "async"
debug       = require "debug"
$           = debug "R20:controllers:question"

Question    = require "../../models/Question"
Story       = require "../../models/Question"
Participant = require "../../models/Participant"

Controller  = require "../ModelController"

prepareMeta = (req, res, done) ->
  $ "Preparing meta"
  res.locals.meta = author: res.locals.participant._id
  done null


module.exports = new Controller Question,
  routes:
    new             : options: pre: prepareMeta
    list            : {}
    single          : options: post: (req, res, done) ->
      async.parallel [
        (done) -> res.locals.question.findStories (error, stories) ->
          $ "Looking for story with question %s", res.locals.question._id
          if error then return done error
          res.locals { stories }
          done null
        (done) ->
          $ "Populating journal with meta.author"
          Participant.populate res.locals.journal,
            path: "meta.author"
            done
      ], done
        

    draft           : options: post: (req, res, done) ->
      async.parallel [
        (done) ->
          $ "Populating journal with meta.author"
          Participant.populate res.locals.journal,
            path: "meta.author"
            done
        (done) ->
          $ "Populating draft with meta.author"
          Participant.populate res.locals.draft,
            path: "meta.author"
            done
      ], done


    apply           : options: pre: prepareMeta
    save            : options: pre: prepareMeta
    remove          : options: pre: prepareMeta
    # reference       : options: pre: prepareMeta
    # remove_reference: options: pre: prepareMeta

  # routes:
  #     list:
  #       pre: (req, res, done) ->
      
  # list:
  #   prepareConditions: (req, res, done) ->
  #     if req.query.query? 
  #       conditions = text: new RegExp req.query.query, "i"
  #       res.locals query: req.query.query
  #     done null, conditions

  # new:
  #   fields: [
  #     "text"
  #   ]
  #   prepareMeta: (req, res, done) -> done null,
  #     author: res.locals.participant._id

  # single:
  #   other_documents: (question, done) ->
  #     $ "Looking for story with question %s", question._id
  #     question.findStories (error, stories) -> done error, { stories }
  #   journal_transformation: (entries, done) ->
  #     Participant.populate entries,
  #       path: "meta.author"
  #       done


  # single_draft:
  #   # populate author
  #   transformation: (draft, done) ->
  #     draft.populate
  #       path  : "meta.author"
  #       model : "Participant"
  #       (error, draft) ->
  #         if error then return done error
  #         $ "After population the draft is: %j", draft
  #         done null, draft

