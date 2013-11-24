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
  get: (req, res) ->
    # Get a list of stories
    $ = $.root.narrow "list"
    
    if req.query.text? 
      conditions = text: new RegExp req.query.text, "i"
      res.locals query: req.query.text

    Story
      .find(conditions)
      # .populate
      #   path  : "questions"
      #   select: "_id text"  
      .exec (error, stories) ->
        if error then throw error
        if (req.accepts ["json", "html"]) is "json"
          res.json stories
        else
          template = require "../views/stories"
          res.locals { stories }
          res.send template.call res.locals

  post: (req, res) ->
    # New story
    $ = $.root.narrow "new"

    story = new Story _.pick req.body, ["text"]
    story.saveDraft
      author: req.session.email
      (error, entry) ->
        $ = $.narrow "draft_saved"
        if error then throw error
        
        if (req.accepts ["json", "html"]) is "json"
          res.json entry.toJSON()
        else
          res.redirect "/story/#{story._id}/draft/#{entry._id}"


  ":id" :
    get   : (req, res) ->
      # Get a single story
      $ = $.root.narrow "single"

      async.waterfall [
        (done) ->
          # Find a story or make a virtual
          $ = $.narrow "find_story"

          if req.query.query?
            conditions = text: new RegExp req.query.query, "i"
            res.locals query: req.query.query


          Story.findByIdOrCreate req.params.id,
            text: "**VIRTUAL**: this story is not saved. Some drafts for it exists though."
            (error, story) ->
              if error then return done error
              story.populate
                path  : "questions"
                match : conditions
                (error, story) ->
                  if error then return done error
                  done null, story
              

        (story, done) -> 
          # Find journal entries
          $ = $.narrow "find_journal_entries"

          story.findEntries (error, entries) ->
            if error then return done error
            if not entries.length and story.isNew then return done Error "Not found"

            done null, story, entries

      ], (error, story, journal) ->
        # Send results
        $ = $.narrow "send"

        if error
          if error.message is "Not found"
            $ "Not found (no story and no drafts)"
            if (req.accepts ["json", "html"]) is "json"
              return res.json 404, error: 404
            else
              return res.send 404, "I'm sorry, I don't know this story."

          else # different error
            throw error 

        if (req.accepts ["json", "html"]) is "json"
          res.json story
        else
          res.locals { story, journal }
          template = require "../views/story"
          res.send template.call res.locals

    put: (req, res) ->
      # Apply a draft or save a new draft
      $ = $.root.narrow "update"

      if req.body._draft? 
        $ "Applying draft %s to story %s", req.body._draft, req.params.id
        
        async.waterfall [
          (done) ->
            # Find draft
            $ = $.narrow "find_draft"

            Entry.findById req.body._draft, (error, draft) ->
              if error then return done error
              if not draft then return done Error "Draft not found"
              if not draft.data._id.equals req.params.id 
                $ "Draft %j doesn't match story %s", draft, req.params.id
                return done Error "Draft doesn't match story"
              done null, draft

          (draft, done) ->
            # Apply draft
            draft.apply author: req.session.email, (error, story) ->
              if error then return done error
              done null, story
        ], (error, story) ->
            if error
              $ "There was en error: %s", error.message
              switch error.message
                when "Draft not found"
                  if (req.accepts ["json", "html"]) is "json"
                    return req.json 409, error: "Draft #{req.body.draft} not found."
                  else
                    return res.send 409, "Draft #{req.body.draft} not found."
                
                when "Draft doesn't match story"
                  if (req.accepts ["json", "html"]) is "json"
                    return req.json 409, error: "Draft #{req.body._draft} doesn't match story #{req.params.id}."
                  else
                    return res.send 409, "Draft #{req.body._draft} doesn't match story #{req.params.id}."
                
                else throw error # different error

            $ "Draft applied"
            if (req.accepts ["json", "html"]) is "json" then req.json story.toJSON()
            else res.redirect "/story/#{story._id}"
      
      # Save a new draft
      else async.waterfall [
        (done) ->
          Story.findByIdOrCreate req.params.id,
            text: "**VIRTUAL**: this story is not saved. Some drafts for it exists though."
            (error, story) ->
              if error then return done error
              _(story).extend _(req.body).pick [
                "text"
              ]
              done null, story

        (story, done) ->
          story.saveDraft author: req.session.email, (error, draft) ->
            $ = $.narrow "saveDraft"
            if error then throw error
            done null, draft
        ], (error, draft) ->
          if error then throw error

          if (req.accepts ["json", "html"]) is "json"
            res.json draft.toJSON()
          else
            res.redirect "/story/#{req.params.id}/draft/#{draft._id}"

    delete: (req, res) ->
      # Delete a single story
      $ = $.root.narrow "delete"

      async.waterfall [
        (done) ->
          # Find a story
          $ = $.narrow "find"

          Story
            .findById(req.params.id)
            .exec (error, story) =>
              if error then return done error
              if not story then return done Error "Not found"

              done null, story

        (story, done) -> 
          # Drop the story
          $ = $.narrow "drop_story"

          story.removeDocument author: req.session.email, (error, entry) ->
            if error then return done error
            
            done null, entry

      ], (error, entry) ->
        # Send results
        $ = $.narrow "send"

        if error
          if error.message is "Not found"
            $ "Story not found."
            if (req.accepts ["json", "html"]) is "json"
              return res.json 404, error: 404
            else
              return res.send 404, "I'm sorry, I don't know this story. Can't drop it."

          else # different error
            throw error 
        

        if (req.accepts ["json", "html"]) is "json"
          res.json entry
        else 
          res.redirect "/story/#{req.params.id}"


    draft:
      get   : (req, res) ->
        # Get a list of single story's drafts
        $ = $.root.narrow "single:drafts:list"

        async.waterfall [
          (done) ->
            # Find a story or make a virtual
            $ = $.narrow "find_story"

            Story.findByIdOrCreate req.params.id,
              text: "**VIRTUAL**: this story is not saved. Some drafts for it exists though."
              (error, story) ->
                if error then return done error
                _(story).extend _(req.body).pick [
                  "text"
                ]
                done null, story
          (story, done) ->
            # Find a drafts
            $ = $.narrow "find_drafts"

            conditions = action: "draft"

            if req.query.query?
              conditions["data.text"] = new RegExp req.query.query, "i"
              res.locals query: req.query.text

            $ "conditions are: ", conditions


            story.findEntries conditions, (error, drafts) ->
              if error then return done error
              if story.isNew and not drafts.length then return done Error "Not found"
              # TODO: above is true when drafts exist, but conditions are not met. It's not what it suppose to do. It should only be true when there is no story and no drafts at all.
              done null, drafts

        ], (error, drafts) ->
          $ = $.narrow "send"

          if error
            if error.message is "Not found"
              $ "Not found (no story and no drafts)"
              if (req.accepts ["json", "html"]) is "json"
                return res.json 404, error: 404
              else
                return res.send 404, "I'm sorry, I don't know this story."

            else # different error
              throw error 

          res.json drafts

          # TODO: html output. Do we need it?
          # if (req.accepts ["json", "html"]) is "json"
          #   res.json story
          # else
          #   res.locals { story, journal }
          #   template = require "../views/story"
          #   res.send template.call res.locals


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
              $ = $.narrow "create_story"
              story = new Story draft.data
              done null, draft, story


            (draft, story, done) ->
              $ = $.narrow "find_other_drafts"
              story.findEntries action: "draft", (error, drafts) ->
                if error then return done error

                done null, draft, story, drafts
          ], (error, draft, story, drafts) ->
            $ = $.narrow "send"
            if error
              if error.message is "Not found"
                if (req.accepts ["json", "html"]) is "json"
                  return res.json 404, error: 404
                else
                  return res.send 404, "I'm sorry, I can't find this draft."
              else # different error
                throw error 

            $ "Drafts are: %j", drafts
            
            if (req.accepts ["json", "html"]) is "json"
              res.json draft
            else 
              res.locals { draft, story, journal: drafts }

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




