# # Controller class
#
# Constructor takes a model and options
# constructs ab object with actual controller logic in paths
# 

async     = require "async"
_         = require "underscore"
Entry     = require "../models/JournalEntry"

debug     = require "debug"
$         = debug "R20:controllers:question"


module.exports = class Controller
  constructor: (@model, @options = {}) ->    
    $.scope = "R20:controller:" + @model.modelName
    {
      model
      options
    } = @
    options = _(options).defaults
      singular  : do model.modelName.toLowerCase
      plural    : model.collection.name
      references: {}  # TODO: build default references by inspecting model
                      # be smart :)

    @paths =
      # General
      get    : (req, res) =>
        # Get a list of all documents
        action = "list"
        $ = $.root.narrow action
        
        $ "Getting a list of %s", options.plural
        
        options[action] ?= {}
        _(options[action]).defaults
          prepareConditions: (req, res, done) -> TODO: done null, {}

        async.waterfall [
          (done)              -> options[action].prepareConditions req, res, done
          (conditions, done)  -> model.find conditions, done
        ], (error, documents) ->
          if error then throw error

          if (req.accepts ["json", "html"]) is "json"
            res.json documents
          else
            template = require "../views/#{options.plural}"
            res.locals[options.plural] = documents
            res.send template.call res.locals

      post: (req, res) ->
        # Store a draft for new question
        action = "new"
        $ = $.root.narrow action
        
        $ "Storing a draft for new %s", options.singular
        
        options[action] ?= {}
        _(options[action]).defaults
          fields: []
          prepareMeta: (req, res, done) -> done null, {}

        document = new model _(req.body).pick options[action].fields

        async.waterfall [
          (done)        -> options[action].prepareMeta req, res, done
          (meta, done)  -> document.saveDraft meta, done
        ], (error, entry) ->
            $ = $.narrow "draft_saved"
            if error then throw error
            
            if (req.accepts ["json", "html"]) is "json"
              res.json entry.toJSON()
            else
              res.redirect "/#{options.singular}" +
                "/#{document._id}" + 
                "/draft/#{entry._id}"

      ":document_id" :
        get : (req, res) ->
          # Store a draft for new question
          action = "single"
          $ = $.root.narrow action
          $ "Getting a singe %s", options.singular
          
          options[action] ?= {}
          _(options[action]).defaults
            getAdditionalDocuments: (document, done) -> done null, {}
            drafts:
              # TODO: the other way around :)
              populate: options.single_draft.populate or (draft, done) -> done null, draft

          async.waterfall [
            (done) ->
              # Find a document or make a virtual
              $ = $.narrow "find_or_create_document"

              model.findByIdOrCreate req.params.document_id,
                text: """
                  **VIRTUAL**
                  This #{options.singular} is not saved.
                  Some drafts for it exists though.
                """
                done
            
            (document, done) ->
              async.parallel
                additionalDocuments: (done) ->
                  options[action].getAdditionalDocuments document, done
                journal: (done) -> document.findEntries done
                (error, data) ->
                  if error then return done error
                  if not data.journal.length and document.isNew
                    return done Error "Not found"
                  # TODO: populate entries on model level!
                  done null, document, data.additionalDocuments, data.journal
            
          ], (error, document, additionalDocuments, journal) ->
            # Send results
            $ = $.narrow "send"

            if error
              if error.message is "Not found"
                $ "Not found (no #{options.singular} and no drafts)"
                if (req.accepts ["json", "html"]) is "json"
                  return res.json 404, error: 404
                else
                  return res.send 404, "I'm sorry, I don't know this #{options.singular}."

              else throw error # different error

            if (req.accepts ["json", "html"]) is "json"
              res.json document
            else
              res.locals[options.singular] = document
              res.locals additionalDocuments
              res.locals { journal }

              template = require "../views/#{options.singular}"
              res.send template.call res.locals

        put: (req, res) ->
          # Apply a draft or save a new draft
          action = "update"
          $ = $.root.narrow action
          
          options[action] ?= {}
          _(options[action]).defaults
            fields      : options.new.fields
            prepareMeta : options.new.prepareMeta

          if req.body._draft?
            $ "Applying draft to a #{options.singular}"
            
            async.waterfall [
              (done) -> options[action].prepareMeta req, res, done
              (meta, done) ->
                # Find a draft
                $ = $.narrow "find_draft"

                Entry.findById req.body._draft, (error, draft) ->
                  if error then return done error
                  if not draft then return done Error "Draft not found"
                  if not draft.data._id.equals req.params.document_id 
                    $ "Draft %j doesn't match #{options.singular} %s", draft, req.params.id
                    return done Error "Draft doesn't match document"
                  done null, meta, draft

              (meta, draft, done) ->
                draft.apply meta, (error, document) ->
                  done error, document
            ], (error, document) ->
              # Send
              $ = $.narrow "send"
              $ "Document is %j", document
              $ "Error is %j", error
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
                      return req.json 409, error: "Draft #{req.body._draft} doesn't match #{options.singular} #{req.params.id}."
                    else
                      return res.send 409, "Draft #{req.body._draft} doesn't match #{options.singular} #{req.params.id}."
                  
                  else throw error # different error

              $ "Draft applied"
              if (req.accepts ["json", "html"]) is "json" then req.json question.toJSON()
              else res.redirect "/#{options.singular}/#{document._id}"
          
          # Save a new draft
          else 
            $ "Saving new draft for #{options.singular}"
            async.parallel
              meta:     (done) -> options[action].prepareMeta req, res, done
              document: (done) ->
                async.waterfall [
                  (done) ->
                    model.findByIdOrCreate req.params.document_id,
                      text: """
                        **VIRTUAL**
                        This #{options.singular} is not saved.
                        Some drafts for it exists though.
                      """
                      done

                  (document, done) ->
                    _(document).extend _(req.body).pick options[action].fields
                    done null, document
                ], done # waterfall
              (error, data) ->
                # parallel callback
                if error then throw error
                data.document.saveDraft data.meta, (error, draft) ->
                  $ = $.narrow "save_draft"
                  if error then throw error
                  if (req.accepts ["json", "html"]) is "json"
                    res.json draft.toJSON()
                  else
                    res.redirect "/question/#{req.params.document_id}/draft/#{draft._id}"

        delete: (req, res) ->
          # Store a draft for new question
          action = "remove"
          $ = $.root.narrow action
          $ "Removing a singe %s", options.singular
          
          options[action] ?= {}
          _(options[action]).defaults
            prepareMeta : options.new.prepareMeta

          async.waterfall [
            (done) ->
              # Find a document
              $ = $.narrow "find"

              model
                .findById(req.params.document_id)
                .exec (error, document) =>
                  if error then return done error
                  if not document then return done Error "Not found"

                  done null, document

            (document, done) ->
              options[action].prepareMeta req, res, (error, meta) ->
                done error, document, meta

            (document, meta, done) -> 
              # Delete document
              $ = $.narrow "delete"

              document.removeDocument meta, (error, entry) ->
                if error then return done error
                done null, entry

          ], (error, entry) ->
            # Send results
            $ = $.narrow "send"

            if error
              if error.message is "Not found"
                $ "Document not found."
                if (req.accepts ["json", "html"]) is "json"
                  return res.json 404, error: 404
                else
                  return res.send 404, "I'm sorry, I don't know this %s. Can't remove it.", options.singular

              else # different error
                throw error 
            
            if (req.accepts ["json", "html"]) is "json"
              res.json entry
            else 
              res.redirect "/#{options.singular}/#{req.params.document_id}"

        draft:
          ":draft_id":
            get: (req, res) ->
              action = "single_draft"
              $ = $.root.narrow action
              
              $ "Getting draft %s for %s", req.params.draft_id, options.plural
              
              options[action] ?= {}
              _(options[action]).defaults
                transformDraft: (draft, done) -> done null, draft

              async.waterfall [
                (done) ->
                  $ = $.narrow "find_draft"
                  Entry.findById req.params.draft_id, (error, entry) ->
                    if error then return done error
                    if (not entry) or
                       (entry.action  isnt "draft") or
                       (entry.model   isnt model.modelName) or
                        not (entry.data?._id?.equals req.params.document_id)
                          return done Error "Not found"

                    return done null, entry

                (draft, done) ->
                  if options[action].populate?
                    $ "Populating draft %j", draft
                    { populate } = options[action]
                    if typeof populate isnt "array" then populate = [ populate ]
                    async.each populate,
                      (spec, next) ->
                        $ "Looking for %s with id %s", spec.model, draft.get spec.path
                        draft.populate spec, next
                      (error) ->
                        $ "All done: %j", draft
                        done error, draft

                (draft, done) ->
                  $ = $.narrow "find_or_create_document"
                  model.findByIdOrCreate draft.data._id,
                    text: """
                      **VIRTUAL**
                      This #{options.singular} is not saved.
                      Some drafts for it exists though.
                    """
                    (error, document) ->
                      if error then return done error
                      done null, draft, document

                (draft, document, done) ->
                  $ = $.narrow "find_other_drafts"
                  document.findEntries action: "draft", (error, journal) ->
                    if error then return done error
                    if options[action].populate?
                      # TODO: DRY
                      # TODO: populate in query, not per document
                      { populate } = options[action]
                      if typeof populate isnt "array" then populate = [ populate ]
                      for entry in journal
                        async.each populate,
                          (spec, next) ->
                            $ "Looking for %s with id %s", spec.model, entry.get spec.path
                            entry.populate spec, next
                          (error) ->
                            $ "All done: %j", entry
                            done error, draft, document, journal

              ], (error, draft, document, journal) ->
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
                  res.locals[options.singular] =  document
                  res.locals { draft, journal }

                  $ "Sending ", { draft, document, journal }

                  template = require "../views/#{options.singular}"
                  res.send template.call res.locals

    $ = $.root.narrow "references"
    for name, reference of options.references
      $ = $.narrow name
      # TODO: reference defaults

      @paths[":document_id"][name] =
        
        get: (req, res) ->
          async.waterfall [
            (done)            -> model.findById req.params.document_id, done
            (document, done)  -> 
              ids = document.get reference.path
              if typeof ids in "array"
                reference.model.find _id: $in: ids, done
              else
                reference.model.findById ids, done
          ], (error, referenced) ->
            if error then throw error
            res.json referenced

        post: (req, res) ->
          async.parallel
            document   : (done) ->
              $ "Looking for document"
              model.findById req.params.document_id, (error, document) ->
                if error then return done error
                if not document then return done Error "Main document not found"
                done null, document

            referenced  : (done) ->
              $ "Looking for referenced document"
              reference.model.findById req.body._id, (error, referenced) ->
                if error then return done error
                if not referenced then return done Error "Referenced document not found"
                done null, referenced
            
            (error, assignment) ->
              # TODO: handle not found errors
              if error then throw error
              # TODO: move to reference  JournalEntry 
              
              {
                document
                referenced
              } = assignment

              field = document.get reference.path
              if reference.type is "has many"
                field.push referenced._id
              else
                field    = referenced._id

              document.set reference.path, field

              document.save (error, document) ->
                $ "Saving reference"
                if error then throw error
                if (req.accepts ["json", "html"]) is "json"
                  res.json document
                else res.redirect "/#{options.singular}/#{document._id}#assignment"

        ":referenced_id":
          delete: (req, res) ->
            operation = $pull: {}
            operation["$pull"][reference.path] = req.params.referenced_id

            model.findByIdAndUpdate req.params.document_id,
              operation
              (error, document) ->
                if not document
                  if (req.accepts ["json", "html"]) is "json"
                    res.json error: "No such #{options.singular}"
                  else res.send "Error: 404"
                  
                if (req.accepts ["json", "html"]) is "json"
                  res.json document
                else res.redirect "/#{options.singular}/#{document._id}"


  # TODO: static method to load (clutters app now)