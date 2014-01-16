# Answers controller

# Models
Answer      = require "../../models/Answer"
Question    = require "../../models/Question"
Participant = require "../../models/Participant"
Entry       = require "../../models/JournalEntry"

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
  root  : "/questions/:question_id/answers"
  routes:
    # list    : options: pre  : pre.conditions

    new     :
      method  : "POST"
      action  : (options, req, res) ->
        async.series [
          # Setup metadata
          (done) -> pre.meta req, res, done
          

          # Find question document
          # We don't really need it, do we? We only need to check if it exists.
          # Is there a more robust name?
          (done) ->
            Question.findById req.params.question_id, (error, question) ->
              if error        then return done error
              if not question then return done HTTPError 404, "Not found"
              res.locals { question }
              done null

          # Check wether there already is an answer by this author
          (done) ->
            { question } = res.locals

            Answer.findOne
              question: question._id
              author  : res.locals.participant._id
              (error, answer) ->
                if error  then return done error
                # Expect to fail :)
                if answer then return done Error2 "Already Answered",
                  message: "This author (#{res.locals.participant.name}) already answered this question (#{res.locals.question.text}). Single author can give only one answer for each question."
                  question: res.locals.question
                  author  : res.locals.participant
                  answer  : answer

                done null
          
          # Check wether there are drafts by this author
          (done) ->
            { question } = res.locals
            Entry.findOne
              model           : "Answer"
              action          : "draft"
              "data.question" : question._id
              "data.author"   : res.locals.participant._id
              (error, draft) ->
                console.dir {error, draft}
                if error  then return done error
                # Expect to fail :)
                if draft then return done Error2 "Answer Already Drafted",
                  message: "This author (#{res.locals.participant.name}) already drafted an answer for this question (#{res.locals.question.text}). Single author can give only one answer for each question. If you want to submit new text, then go to answer, and save new draft."
                  question: question
                  author  : res.locals.participant
                  answer  : draft.data

                done null


          # Create new answer document
          (done) ->
            answer = new Answer
              text    : req.body.text
              author  : res.locals.participant
              question: req.params.question_id

            answer.saveDraft author: res.locals.participant._id, (error, draft) ->
              if error then return done error
              res.locals { draft }
              done null
        ], (error) ->
          if error 
            if error.name in ["Already Answered", "Answer Already Drafted"]
              return res.send 409, error.message
            else
              throw error

          {
            question
            draft
          } = res.locals

          res.redirect "/questions/#{question._id}/answers/#{draft.data._id}/drafts/#{draft._id}"
    
    single          : options: post : (req, res, done) ->
      { answer } = res.locals
      async.series [
        (done) ->
          if answer.isNew then answer.question = req.params.question_id
          done null
        (done) -> answer.populate "question author", done
        (done) ->
          Participant.populate res.locals.journal,
            path: "meta.author"
            done
      ], done
        

    draft           : options: post: (req, res, done) ->
      { draft } = res.locals
      async.parallel [
        (done) -> post.draft req, res, done
        (done) -> Question.populate     draft, path: "data.question" , done
        (done) -> Participant.populate  draft, path: "data.author"   , done
      ], done

    apply           : options:
      pre   : pre.meta
      post  : (req, res, done) ->
        { draft } = res.locals
        res.locals.redirect = "/questions/#{draft.data.question}##{draft.data._id}"
        done null

    save            : options: pre: pre.meta
    remove          : options:
      pre   : pre.meta
      post  : (req, res, done) ->
        { question } = res.locals
        res.locals.redirect = "/questions/#{req.params.question_id}"
        done null
