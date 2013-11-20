# Search controller

_     = require "underscore"
async = require "async"
debug = require "debug"

Story     = require "../models/Story"
Question  = require "../models/Question"
Entry     = require "../models/JournalEntry"

$ = debug "R20:controllers:story"

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
    # New story
    story = new Story _.pick req.body, ["text"]
    story.saveDraft
      author: req.session.email
      (error, entry) ->
        if error then throw error
        
        if (req.accepts ["json", "html"]) is "json"
          res.json story.toJSON()
        else
          res.redirect "/story/#{story._id}"


  ":id" :
    # Single
    get   : (req, res) ->
      # Get a single story
      $ = $.narrow "single:get"

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

          if (req.accepts ["json", "html"]) is "json"
              res.json story.toJSON() or error: 404
          else
            if not story then story = new Story
              text: "*NOT YET SAVED*"
              _id : req.params.id

            # TODO: be smarter - only do it when journal has some entries. + async.parallel
            res.locals { story }

            story.findDrafts (error, drafts) ->
              if error then throw error
              $ "Drafts are %j", drafts
              res.locals.drafts = drafts
        
          
            # if not story
            #   return res.send 404, "I'm sorry, but I don't know this story :("

              template = require "../views/story"
              res.send template.call res.locals

    put: (req, res) ->
      # Update a single story
      Story.findById req.params.id, (error, story) =>
          if error      then throw error
          if not story  then return res.send "I'm sorry, but I don't know this story :("

          _(story).extend _(req.body).pick [
            "text"
          ]

          story.storeVersion author: req.session.email, (error, entry) ->
            $ = $.narrow "storeVersion"
            if error then throw error

            $ "New version stored: %j", story
            if (req.accepts ["json", "html"]) is "json"
              res.json story.toJSON()
            else
              res.redirect "/story/#{story._id}"

    draft:
      ":draft_id":
        get: (req, res) ->
          $ = $.narrow "single:draft:single"
          Entry.findById req.params.draft_id, (error, entry) ->
            if error then throw error
            $ "Draft entry is %j", entry
            if not entry or entry.action isnt "draft" or not entry.data?._id?.equals req.params.id
              if (req.accepts ["json", "html"]) is "json" then return res.json 404, error: 404
              else return res.send 404, "No such draft."

            if (req.accepts ["json", "html"]) is "json" then res.json entry.toJSON()
            else 
              story = new Story entry.data
              res.locals { story }
              res.locals.story.isDraft = yes
              template = require "../views/story"
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
              if not story
                if (req.accepts ["json", "html"]) is "json"
                  res.json error: "No such story"
                else res.send "Error: No such story"
                
              if (req.accepts ["json", "html"]) is "json"
                res.json story
              else res.redirect "/story/#{story._id}"




