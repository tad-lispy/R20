# Answers controller

# Models
Answer      = require "../../models/Answer"
Question    = require "../../models/Question"
Participant = require "../../models/Participant"

# Controller
Controller  = require "../ModelController"
HTTPError   = require "../../HTTPError"
Error2      = require "error2"

# Helpers
async       = require "async"
pre =
  meta      : require "../prepare-meta"
  conditions: require "../prepare-conditions"
post  =
  draft     : require "../post-draft"
async       = require "async"
debug       = require "debug"
$           = debug "R20:controllers:answers"

module.exports = new Controller Answer,
  routes:
    list    : options: pre  : pre.conditions

    new     :
      url     : "/questions/:question_id/answers"
      method  : "POST"
      action  : (options, req, res) ->
        async.series [
          # Setup metadata
          (done) -> pre.meta req, res, done
          
          # Find question document
          (done) ->
            Question.findById req.params.question_id, (error, question) ->
              if error        then return done error
              if not question then return done HTTPError 404, "Not found"
              res.locals { question }
              done null

          # Check wether there already is an answer by this author
          (done) ->
            { question } = res.locals
            $ "Question: ", question
            Answer.find
              _id     : $in: question.answers
              author  : res.locals.participant
              (error, answer) ->
                if error  then return done error
                # Expect to fail :)
                if answer then return done Error2 "AlreadyAnsweredError",
                 "There is already an answer by this author (#{res.locals.participant.name}) to this question."

                done null
              
          # Create new answer document
          (done) ->
            answer = new Answer
              text    : req.body.text
              author  : res.locals.participant
              question: res.params.question_id

            answer.save (error) ->
              if error then return done error
              res.locals { ansewer }
              done null
        ], (error) ->
          if error then throw error

          {
            question
            answer
          } = res.locals

          res.redirect "/questions/#{question._id}##{answer._id}"
    
    single          : options: post : (req, res, done) ->
      async.parallel [
        (done) -> res.locals.question.findStories (error, stories) ->
          $ "Looking for stories with question %s", res.locals.question._id
          if error then return done error
          res.locals { stories }
          done null
        (done) -> 
          res.locals answers: []
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
