###

# Controller class

Constructor takes a model and options and constructs an object with actual controller logic in paths.
Controller object can be plugged into app.

ModelController has following actions

* list: 
    list documents

* journal:
    list journal entries for documents in a given model
    (all, drafts, refererences, pending (newer then applied one), hanging (for new documents), etc.)

* new:
    create new document or * store a draft for it

* single:
    get single document

* update:
    update a single document or * store new draft

* remove:
    remove a document

* document_journal:
    get entries for single document

* single_entry:
    get a single draft for a single document
    Obsolete since you can get /draft/:draft_id?

* list_references:
    lists all references of a given type

* single_reference:
    seldom used - mainly for singular reference

* make_reference:
    add a reference to other document

* unreference:
    remove a reference to other document

When creating new controller you pass it a model and options, eg:

new Controller Question,
  root  : /interesting-questions/
  routes:
    list:
      options:
        pre : (req, res, done) -> done error
        post: (req, res, done) -> done error
```

Default behaviour doesn't require any options. Just pass a model and ModelController will figure out what to do with it.

Route options are passed to appropriate actions. Usualy options are functions to be called at a given stages of async.series.

If options[action] is a function, then it overrides entire action method. `this` is a controller.

Controller maps url paths to actions. This path can also be overriden by options. Default mapping is:

Action              | Method  | URL path
---------------------------------------------------------------------------------------
✓ list              | GET     | /
✓ new               | POST    | /
  journal           | GET     | /journal
✓ single            | GET     | /:document_id
✓ apply             | PUT     | /:document_id
✓ save              | POST    | /:document_id/drafts
✓ remove            | DELETE  | /:document_id
  single_journal    | GET     | /:document_id/journal/
✓ draft             | GET     | /:document_id/journal/:entry_id
  list_references   | GET     | /:document_id/:reference_path/ *if reference is plural*
  single_reference  | GET     | /:document_id/:reference_path/ *if reference isingular*
  single_reference  | GET     | /:document_id/:reference_path/:reference_id
  make_reference    | PUT     | /:document_id/:reference_path/:reference_id
  unreference       | DELETE  | /:document_id/:reference_path/:reference_id
  
###

async       = require "async"
_           = require "lodash"
path        = require "path"
HTTPError   = require "../HTTPError"

Controller  = require "express-controller"

Entry       = require "../models/JournalEntry"
  
debug       = require "debug"
$           = debug   "R20:ModelController"


module.exports = class ModelController extends Controller
  constructor       : (@model, options = {}) ->

    $ "New model controller: %j", options    
    _(options).defaults
      singular  : do @model.modelName.toLowerCase
      plural    : @model.collection.name

    _(options).defaults
      name      : options.plural

    _(options).defaults
      root      : "/" + options.name
      views     : path.resolve require.main.filename, "..", "views/", options.name
    
    {
      singular
      plural
      name
      root
      views
    } = options

    templates =
      list  : require "#{views}/list"
      single: require "#{views}/single"
      
    routes = 
      list              : 
        method            : "GET"
        url               : root
        action            : (options, req, res) =>
          route = @routes.list
          $ "Getting list of %s", plural
          async.series [
            (done) => options.pre req, res, done
            (done) =>
              # Use `options.pre` to set `conditions`
              @model.find res.locals.conditions, (error, documents) =>
                if error then return done error
                res.locals[plural] = documents
                done null
            (done) => options.post req, res, done
          ], (error) =>
            if error then throw error
            if (req.accepts ["json", "html"]) is "json"
              res.json res.locals[plural]
            else
              res.send templates.list res.locals


      new               : 
        method            : "POST"
        url               : root
        action            : (options, req, res) =>
          route = @routes.new
          $ "Making new %s", singular
          
          _.defaults options,
            fields: _.keys(@model.schema.paths).filter (field) ->
              not field.match /^_/ # All fields except for prefixed with _

          async.waterfall [
            # Use pre to prepare meta for journal entry
            (done) => options.pre  req, res, done
            (done) =>
              document = new model _.pick req.body, options.fields
              $ "Saving document %j", document
              document.saveDraft res.locals.meta, (error, draft) ->
                if error then return done error
                res.locals { draft }
                done null
            (done) => options.post req, res, done
          ], (error) =>
            if error then throw error
            { draft } = res.locals
            if (req.accepts ["json", "html"]) is "json"
              res.json res.locals.draft
            else
              res.redirect root + "/" + draft.data._id + "/drafts/" + draft._id


      # journal           : 
      #   path              : "#{@options.root}/journal"
      #   method            : "GET"
      #   action            : (req, res) =>
      #     $ "Getting list of journal entries about %s", @options.plural

      single            : 
        method            : "GET"
        url               : "#{root}/:document_id"
        action            : (options, req, res) =>
          route = @routes.single
          $ "Getting a single %s", singular
          async.series [
            (done) => options.pre req, res, done

            # Find a document or make a virtual
            (done) =>
              model.findByIdOrCreate req.params.document_id,
                text: """
                  VIRTUAL
                  This #{singular} is not saved or was removed.
                  Some drafts for it exists though.
                """
                (error, document) ->
                  if error then return done error
                  res.locals[singular] = document
                  done null

            # Find journal entries
            (done) =>
              document = res.locals[singular]
              document.findEntries (error, journal) ->
                if error then return done error
                if not  journal.length and
                        document.isNew then return done Error "Not found"
                res.locals { journal }
                done null
            (done) => options.post req, res, done
          ], (error) =>
            if error
              if error.message is "Not found"
                if (req.accepts ["json", "html"]) is "json"
                  return res.json 404, error: 404
                else
                  return res.send 404, "I'm sorry, I can't find this draft."
              else # different error
                throw error 

            if (req.accepts ["json", "html"]) is "json"
              res.json res.locals[singular]
            else
              res.send templates.single res.locals


      apply             :
        method            : "PUT"
        url               : "#{root}/:document_id"
        action            : (options, req, res) =>
          route = @routes.apply
          $ "Applying draft of %s", singular
          
          async.series [
            (done) ->
              if not req.body._draft then done HTTPError 409, "Malformed request body"
              done null

            (done) -> options.pre req, res, done
            
            # Find draft mentioned in the request body
            (done) ->
              Entry.findById req.body._draft, (error, draft) ->
                if error then return done error
                if not draft then return done Error "Draft not found"
                if not draft.data._id.equals req.params.document_id 
                  $ "Draft %j doesn't match %s %s", draft, singular, req.params.id
                  return done HTTPError 409, "Draft doesn't match document"
                res.locals { draft }
                done null

            (done) -> res.locals.draft.apply res.locals.meta, (error, document) ->
              if error then return done error
              res.locals[singular] = document
              done null

            (done) -> options.post req, res, done

          ], (error) =>
            if error
              $ "There was en error: %j", error
              switch error.message
                when "Draft not found"
                  if (req.accepts ["json", "html"]) is "json"
                    return req.json 409, error: "Draft #{req.body.draft} not found."
                  else
                    return res.send 409, "Draft #{req.body.draft} not found."
                
                when "Draft doesn't match document"
                  if (req.accepts ["json", "html"]) is "json"
                    return req.json 409, error: "Draft #{req.body._draft} doesn't match #{singular} #{req.params.id}."
                  else
                    return res.send 409, "Draft #{req.body._draft} doesn't match #{singular} #{req.params.id}."

                when "Malformed request body"
                  if (req.accepts ["json", "html"]) is "json"
                    return req.json 409, error: "Maleformed request body. It should contain _draft property with id of draft to apply."
                  else
                    save = @routes.save
                    return res.send 409, """
                      Malformed request body.<br/>
                      It should contain _draft property with id of draft to apply.<br/>
                      If you want to save a new draft, then make a #{save.method} request to #{save.url}.
                    """
                
                else throw error # different error

            $ "Draft applied"
            document = res.locals[singular]
            if (req.accepts ["json", "html"]) is "json" then req.json document.toJSON()
            else res.redirect root + "/" + document._id

      save              :
        method            : "POST"
        url               : "#{root}/:document_id/drafts"
        action            : (options, req, res) =>
          route = @routes.save
          $ "Saving new draft of %s", singular

          _.defaults options,
            fields: _.keys(@model.schema.paths).filter (field) ->
              not field.match /^_/ # All fields except for prefixed with _

          
          async.series [
            (done) => options.pre req, res, done
            
            # Find or create a document
            (done) => 
              @model.findByIdOrCreate req.params.document_id,
                text: """
                  VIRTUAL
                  This #{singular} is not saved.
                  Some drafts for it exists though.
                """
                (error, document) ->
                  if error then return done error
                  data      = _.pick req.body, options.fields
                  document  = _.extend document, data
                  
                  res.locals[singular] = document
                  done null

            # Save draft
            (done) =>
              document = res.locals[singular]
              { meta } = res.locals

              document.saveDraft meta, (error, draft) ->
                if error then return done error
                res.locals { draft }
                done null

          ], (error) ->
            if error then throw error
            { draft } = res.locals
            document  = res.locals[singular]

            if (req.accepts ["json", "html"]) is "json" then req.json draft.toJSON()
            else res.redirect root + "/" + document._id + "/drafts/" + draft._id


      remove            : 
        method            : "DELETE"
        url               : "#{root}/:document_id"
        action            : (options, req, res) =>
          route = @routes.remove
          $ "Removing %s", singular

          async.series [
            (done) => 
              options.pre req, res, done

            # Find a document
            (done) =>
              @model
                .findById req.params.document_id, (error, document) =>
                  if error then return done error
                  if not document then return done HTTPError 404, "Not found"

                  res.locals[singular] = document
                  done null

            # Delete document
            (done) =>
              document = res.locals[singular]
              document.removeDocument res.locals.meta, (error, entry) ->
                if error then return done error
                res.locals { entry }
                done null

          ], (error) =>
            # Send results
            $ = $.narrow "send"

            if error
              if error.message is "Not found"
                $ "Document not found."
                if (req.accepts ["json", "html"]) is "json"
                  return res.json 404, error: "#{singular} not found, Can't remove if it's not there."
                else
                  return res.send 404, "#{singular} not found, Can't remove if it's not there."

              else # different error
                throw error 
            
            if (req.accepts ["json", "html"]) is "json"
              res.json entry
            else 
              res.redirect root


      # single_journal    : 
      #   path              : "#{@options.root}/:document_id/journal"
      #   method            : "GET"
      #   action            : (req, res) =>
      #     $ "Getting journal entries about single %s", @options.singular

      draft             :
        method            : "GET"
        url               : root + "/:document_id/drafts/:draft_id"
        action            : (options, req, res) ->
          route = @routes.single_draft
          $ "Getting %s draft %s", req.params.draft_id, singular
          async.series [
            (done) => options.pre req, res, done
            # Find draft
            (done) =>
              Entry.findById req.params.draft_id, (error, entry) =>
                if error then return done error
                if (not entry) or
                   (entry.action  isnt "draft") or
                   (entry.model   isnt @model.modelName) or
                    not (entry.data?._id?.equals req.params.document_id)
                      return done Error "Not found"
                res.locals draft: entry
                done null
            # Find or create document
            (done) =>
              @model.findByIdOrCreate res.locals.draft.data._id,
                text: """
                  VIRTUAL
                  This #{singular} is not saved.
                  Some drafts for it exists though.
                """
                (error, document) ->
                  if error then return done error
                  res.locals[singular] = document
                  done null
            # Find journal entries (including other drafts)
            (done) =>
              document = res.locals[singular]
              document.findEntries (error, journal) ->
                if error then return done error
                # $ "Here", {document, journal}, 
                # if (not journal.lenght) and # Can't happen :P
                #         document.isNew  then return done Error "Not found"
                res.locals { journal }
                done null

            (done) => options.post req, res, done
          ], (error) =>
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
              res.send templates.single res.locals

      # single_entry      : # Do we need it?
      #   path              : "#{@options.root}/:document_id/journal/:entry_id"
      #   method            : "GET"
      #   action            : (req, res) =>
      #     $ "Getting single journal entry about %s", @options.singular

    # Discover and setup references routes
    references        = _.omit model.references, (reference, path) -> path.match /^_/
    _.merge references, options.references
    $ "References are: %j", references
    for path, reference of references
      reference_model = @model.model reference.model

      if reference.relation is "has many" 
        # List, Add and Single are only availabel for has many type references
        routes[reference.path + "_list"] = 
          method            : "GET"
          url               : root + "/:document_id/" + reference.path
          action            : (options, req, res) =>
            route = @routes[reference.path + "_list"]
            $ "Geting list of %s references for %s", reference.path, singular
            async.series [
              (done) => options.pre req, res, done

              # Find document
              (done) =>
                @model.findById req.params.document_id, (error, document) ->
                  if error then return done error
                  if not document then return done new HTTPError 404, "Not found"
                  res.locals[singular] = document
                  done null

              
              (done) =>
                document = res.locals[singular]
                ids = document.get reference.path
                $ "Ids are (%s) %j ", typeof ids, ids
                reference_model.find _id: $in: ids, (error, documents) =>
                  if error then return done error
                  res.locals[reference.path] = documents
                  done null

              (done) => options.post req, res, done

            ], (error) =>
              if error
                if error.code is 404 then res.send "#{singular} not found. Thus no #{reference.path}."
                else throw error

              res.json res.locals[reference.path]

        routes[reference.path + "_add"] =
          method  : "POST"
          url     : root + "/:document_id/" + reference.path
          action            : (options, req, res) =>
            route = @routes[reference.path + "_add"]
            $ "Adding a reference to %s into %s", reference.path, singular
            async.series [
              (done) => options.pre req, res, done

              # Find document
              (done) =>
                @model.findById req.params.document_id, (error, document) ->
                  if error then return done error
                  if not document then return done HTTPError 404, """
                    Main document not found.
                    Can't add a anything to #{reference.path} of a #{singular} that doesn't exist.
                  """
                  res.locals[singular] = document
                  done null

              # Find referenced document
              (done) => 
                { meta }    = res.locals
                document    = res.locals[singular]
                if not req.body._id then return done HTTPError 409, """
                  Malformed request body.
                  It should containd _id attribute pointing to document of type #{reference.model}. It does not.
                """
                reference_model.findById req.body._id, (error, referenced) ->
                  if error then return done error
                  if not referenced then return done HTTPError 409, """
                    Referenced document not found.
                    #{reference.model} #{req.body._id} not found.
                  """
                  res.locals[reference.path] = referenced
                  done null

              # Save reference
              (done) =>
                document    = res.locals[singular]
                referenced  = res.locals[path]
                { meta }    = res.locals

                document.saveReference path, referenced, meta, (error, entry) =>
                  if error then return done error
                  res.locals { entry }
                  done null

              (done) => 
                document    = res.locals[singular]
                referenced  = res.locals[path]
                { meta
                  entry
                }    = res.locals

                entry.apply meta, done

              (done) => options.post req, res, done
            ], (error) =>
              if error
                if error instanceof HTTPError then return res.json error
                else throw error

              document    = res.locals[singular]

              res.redirect root + "/" + document._id


        routes[reference.path + "_delete"] =
          method  : "DELETE"
          url     : root + "/:document_id/" + reference.path + "/:reference_id"
          action  : (options, req, res) =>
            route = @routes[reference.path + "_delete"]
            $ "Removing a reference to %s from %s", reference.path, singular
            {
              document_id
              reference_id
            } = req.params

            async.series [
              (done) => options.pre req, res, done
              (done) =>
                {
                  document_id
                  reference_id
                } = req.params
                model.findById document_id, (error, document) =>
                  if error then return done error
                  if not document then return done HTTPError 404, "Not found"
                  res.locals[singular] = document 
                  done null

              (done) =>
                document = res.locals[singular]
                { meta } = res.locals      

                document.removeReference reference.path,
                  reference_id
                  meta
                  (error, entry) =>
                    console.dir { entry }
                    if error then return done error
                    entry.apply meta, done

              (done) => options.post req, res, done

            ], (error) =>
              if error
                if error instanceof HTTPError then return res.json error
                else throw error

              document = res.locals[singular]

              res.redirect root + "/" + document._id


    # Default options are the same for all routes
    for name of routes
      routes[name].options = 
        pre               : (req, res, done) -> process.nextTick -> done null
        post              : (req, res, done) -> process.nextTick -> done null






      # list_references   : 
      #   method            : "GET"
      #   url               : root + "/:document_id/:reference_path"
      #   action            : (options, req, res) ->
      #     route = @routes.list_references
      #     $ "Geting %s reference of %s", req.params.reference_path, singular

      # single_reference  : 
      #   path              : "#{@options.root}/:document_id/:reference_path/:reference_id/"
      #   method            : "GET"
      #   action            : (req, res) =>
      #     $ "Getting a single %s referencing single %s", req.params.reference_path, @options.singular

      # add_reference     : 
      #   method            : "POST"
      #   url               : root + "/:document_id/:reference_path"
      #   action            : (options, req, res) ->
      #     route = @routes.add_reference
      #     $ "Adding a reference to %s into %s", req.params.reference_path, singular
      #     # async.series [
      #     #   (done) => options.pre req, res, done



      # remove_reference  : 
      #   path              : "#{@options.root}/:document_id/:reference_path/"
      #   method            : "POST"
      #   action            : (req, res) =>
      #     $ "Removing a single %s reference of single %s", req.params.reference_path, @options.singular
    

    options.routes = _(routes).merge(options.routes).value()
    $ "Calling super with options: %j", options
    super options


  
