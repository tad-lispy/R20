# Search controller

_     = require "underscore"
async = require "async"

Story     = require "../models/Story"
Question  = require "../models/Question"

module.exports =
  # General
  get    : (req, res) ->
    # Get a list of stories
    if req.query.text? 
      conditions = text: new RegExp req.query.text, "i"
      res.locals query: req.query.text

    Story
      .find(conditions)
      .populate
        path  : "questions"
        select: "_id text"  
      .exec (error, stories) ->
        if error then throw error
        if (req.accepts ["json", "html"]) is "json"
          res.json stories
        else
          template = require "../views/stories"
          res.locals { stories }
          res.send template.call res.locals

  post    : (req, res) ->
    # Store a new one
    story = new Story _.pick req.body, ["text"]

    story.save (error, story) ->
      if error then throw error
      res.redirect "/story/#{story._id}"

  ":id" :
    # Single
    get   : (req, res) ->
      # Get a single story

      # filter questions by text
      if req.query.text?
        conditions = text: new RegExp req.query.text, "i"
        res.locals query: req.query.text

      Story
        .findById(req.params.id)
        .populate
          path  : "questions"
          match : conditions
        .exec (error, story) =>
          if error then throw error
          res.locals { story }
          
          if (req.accepts ["json", "html"]) is "json"
            res.json story or error: 404

          else
            if not story
              return res.send 404, "I'm sorry, but I don't know this story :("
            template = require "../views/story"
            res.send template.call res.locals

    put: (req, res) ->
      # Update a single story
      Story.findByIdAndUpdate req.params.id,
        _.pick req.body, [
          "text"
          "questions"
        ]
        (error, story) =>
          if error      then throw error
          if not story  then return res.send "I'm sorry, but I don't know this story :("

          template = require "../views/story"

          res.locals.story = story
          res.send template.call res.locals

    questions:
      # Assign a question to a story
      # Expect an object representing a question, at least { _id }
      post : (req, res) ->
        async.parallel
          story   : (done) ->
            Story.findById req.params.id, (error, story) ->
              if error then return done error
              if not story then return done Error "Story not found"
              done null, story

          question: (done) ->
            Question.findById req.body._id, (error, question) ->
              if error then return done error
              if not question then return done Error "Question not found"
              done null, question
          
          (error, assignment) ->
            if error then throw error
            assignment.story.questions.push assignment.question

            assignment.story.save (error, story) ->
              if error then throw error
              if (req.accepts ["json", "html"]) is "json"
                res.json story
              else res.redirect "/story/#{story._id}#assignment"

      ":qid":
        delete: (req, res) ->
          Story.findByIdAndUpdate req.params.id,
            $pull: questions: req.params.qid
            (error, story) ->
              if (req.accepts ["json", "html"]) is "json"
                res.json story
              else res.redirect "/story/#{story._id}"




