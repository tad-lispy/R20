# Question controller

# Models
Question    = require "../../models/Question"
Participant = require "../../models/Participant"
Entry       = require "../../models/JournalEntry"

# Controller
Controller  = require "../ModelController"

# Helpers
pre =
  meta      : require "../prepare-meta"
  conditions: require "../prepare-conditions"
post  =
  draft     : require "../post-draft"
async       = require "async"
debug       = require "debug"
$           = debug "R20:controllers:question"

module.exports = new Controller Question,
  routes:
    list            : options: pre  : pre.conditions

    new             : options: pre  : pre.meta
    
    single          : options: post : (req, res, done) ->
      async.series [
        (done) -> res.locals.question.findStories (error, stories) ->
          if error then return done error
          res.locals { stories }
          done null
        
        (done) -> res.locals.question.findAnswers (error, answers) ->
          if error then return done error
          res.locals { answers }

          done null

        # Check if there are drafts of answers by this participant
        (done) ->
          {
            participant
            question
            answers
          } = res.locals
          query = Entry.findOne
            model : "Answer"
            action: "draft"
            "data.author"   : participant._id
            "data.question" : question._id

          query.sort _id: -1
          query.exec (error, entry) ->
            if error then return done error
            if entry then answers.drafted = entry.data
            done null
        
        (done) ->
          { answers } = res.locals
          Participant.populate answers,
            path: "author"
            (error, answers) ->
              done null

        (done) ->
          $ "Populating journal with meta.author"
          Participant.populate res.locals.journal,
            path: "meta.author"
            done
      ], done
        

    draft           : options: post: post.draft

    apply           : options: pre: pre.meta
    save            : options: pre: pre.meta
    remove          : options: pre: pre.meta

    # TODO:
    # reference       : options: pre: pre.meta
    # remove_reference: options: pre: pre.meta
