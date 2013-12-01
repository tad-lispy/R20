# # Controller class
#
# Constructor takes a model and options
# constructs ab object with actual controller logic in paths
# 
# TODO: Too long! Modularize.

async     = require "async"
_         = require "underscore"
Entry     = require "../models/JournalEntry"

debug     = require "debug"
$         = debug "R20:Controllers:factory"


module.exports = class Controller
  constructor: (@model, @options = {}) ->    
    $.scope = "R20:controller:" + @model.modelName
    {
      model
      options
    }       = @
    options = _(options).defaults
      singular  : do model.modelName.toLowerCase
      plural    : model.collection.name
      references: []  # TODO: build default references by inspecting model
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
        # Store a draft for new document
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
          # get a single document
          action = "single"
          $ = $.root.narrow action
          $ "Getting a singe %s", options.singular
          
          options[action] ?= {}
          _(options[action]).defaults
            transformation  : (document, done) -> process.nextTick -> done null, document
            other_documents : (document, done) -> process.nextTick -> done null, {}

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
                other_documents: (done) ->
                  options[action].other_documents document, done

                transformation: (done) ->
                  options[action].transformation  document, done

                journal       : (done) ->
                  document.findEntries done

                (error, data) ->
                  if error then return done error
                  if not data.journal.length and document.isNew
                    return done Error "Not found"
                  done null, data.transformation, data.other_documents, data.journal
            
          ], (error, document, other_documents, journal) ->
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
              res.locals other_documents
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
              if (req.accepts ["json", "html"]) is "json" then req.json document.toJSON()
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
                    res.redirect "/#{options.singular}/#{req.params.document_id}/draft/#{draft._id}"

        delete: (req, res) ->
          # Remove a document
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
                transformation: (draft, done) -> process.nextTick -> done null, draft

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

                # Run transformation (to populate, etc.)
                options[action].transformation

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
    references        = model.references
    _(references).union options.references

    $ "References are: %j", references

    setup_reference_paths = (reference_model, reference_relation, reference_path) =>
      $ = $.root.narrow reference.path
      $ "building reference paths for %j", {reference_model, reference_relation, reference_path}
      @paths[":document_id"][reference.path] =
        get: (req, res) ->
          async.waterfall [
            (done)            -> model.findById req.params.document_id, done
            (document, done)  -> 
              if not document then return done Error "Not found"
              $ "%s %s %s", model.modelName, reference_relation, reference_model.modelName

              if reference_relation is "has many"
                ids = document.get reference_path
                $ "Ids are (%s) %j ", typeof ids, ids
                reference_model.find _id: $in: ids, done
              else
                id = document.get reference_path
                reference_model.findById id, done
                  
          ], (error, referenced) ->
            if error 
              if error.message is "Not found"
                if (req.accepts ["json", "html"]) is "json"
                  return res.json 404, error: 404
                else
                  return res.send 404, "I'm sorry, I can't find this #{options.singular}."
              else throw error
            res.json referenced

        post: (req, res) ->
          # Remove a reference
          action = "reference_" + reference_path
          $ = $.root.narrow action
                     
          options[action] ?= {}
          _(options[action]).defaults
            prepareMeta: options.new.prepareMeta

          { 
            document_id
          } = req.params

          async.parallel
            document   : (done) ->
              $ "Looking for document"
              model.findById req.params.document_id, (error, document) ->
                if error then return done error
                if not document then return done Error "Main document not found"
                done null, document

            referenced  : (done) ->
              $ "Looking for referenced document"
              reference_model.findById req.body._id, (error, referenced) ->
                if error then return done error
                if not referenced then return done Error "Referenced document not found"
                done null, referenced

            meta        : (done) -> 
              options[action].prepareMeta req, res, done
            
            (error, assignment) ->
              # TODO: handle not found errors
              if error then throw error
              # TODO: move to reference  JournalEntry 
              
              {
                document
                referenced
              } = assignment

              field = document.get reference_path
              if reference_relation is "has many"
                field.push referenced._id
              else
                field    = referenced._id

              document.set reference_path, field

              document.save (error, document) ->
                $ "Saving reference"
                if error then throw error

                entry = new Entry
                  action: "reference"
                  model : model.modelName
                  data  :
                    main_doc      : document_id
                    referenced_doc: referenced._id
                    path          : reference_path
                  meta  : assignment.meta
                entry.save (error, entry) ->
                  if (req.accepts ["json", "html"]) is "json"
                    res.json document
                  else res.redirect "/#{options.singular}/#{document._id}#assignment"

        ":referenced_id":
          delete: (req, res) ->
            # Remove a reference
            action = "unreference_" + reference_path
            $ = $.root.narrow action
                       
            options[action] ?= {}
            _(options[action]).defaults
              prepareMeta: options.new.prepareMeta

            { 
              document_id
              referenced_id
            } = req.params


            conditions = _id: document_id
            conditions[reference_path] = referenced_id

            if reference_relation is "has many"
              operation = $pull: {}
              operation["$pull"][reference_path] = referenced_id
            else
              operation = {}
              operation[reference_path] = null

            $ "Removing reference to %s (%s) from %s (%s)",
              reference_model.modelName
              referenced_id
              model.modelName
              document_id
            
            async.waterfall [
              # Try to do it
              (done)  -> model.findOneAndUpdate conditions, operation, done
              
              # Check if anything happened. I so, save an entry
              (document, done) ->
                if not document then return done Error "Reference not found in document"
                done null, document
              
              # Prepare metadata for journal
              (document, done) ->
                console.dir {req, res, done}
                options[action].prepareMeta req, res, (error, meta) ->
                  done error, document, meta

              # Save entry in a journa;
              (document, meta, done) ->
                entry = new Entry
                  action: "unreference"
                  model : model.modelName
                  data  : {
                    main_doc      : document_id
                    referenced_doc: referenced_id
                    path          : reference_path
                  }
                  meta  : meta
                entry.save (error, entry) -> done error, document, entry

            ], (error, document, entry) ->
                if error then switch error.message
                  when "Reference not found in document"
                    if (req.accepts ["json", "html"]) is "json"
                      res.json 409, error: "Reference not found in document"
                    else res.send "Error: 404"
                  
                if (req.accepts ["json", "html"]) is "json"
                  res.json document
                else res.redirect "/#{options.singular}/#{document_id}"

    for reference in references
      setup_reference_paths (model.model reference.model), reference.relation, reference.path

    
        
        

  # TODO: static method to load (clutters app now)