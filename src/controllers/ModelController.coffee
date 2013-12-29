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

* remove_reference:
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

  Action            | Method | URL path
  ---------------------------------------------------------------------------------------
  list              | GET    | /
  new               | POST   | /
  journal           | GET    | /journal
  single            | GET    | /:document_id
  update            | PUT    | /:document_id
  remove            | DELETE | /:document_id
  single_journal    | GET    | /:document_id/journal/
  single_entry      | GET    | /:document_id/journal/:entry_id
  list_references   | GET    | /:document_id/:reference_path/ *if reference is plural*
  single_reference  | GET    | /:document_id/:reference_path/ *if reference is singular*
  single_reference  | GET    | /:document_id/:reference_path/:reference_id
  make_reference    | PUT    | /:document_id/:reference_path/:reference_id
  remove_reference  | DELETe | /:document_id/:reference_path/:reference_id

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
          $ "%s %s", route.method, route.url
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
          $ "%s %s", route.method, route.url
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
      #     $ "%s %s", @actions.journal.method, @actions.journal.path
      #     $ "Getting list of journal entries about %s", @options.plural

      single            : 
        method            : "GET"
        url               : "#{root}/:document_id"
        action            : (options, req, res) =>
          route = @routes.single
          $ "%s %s", route.method, route.url
          $ "Getting a single %s", singular
          async.series [
            (done) => options.pre req, res, done

            # Find a document or make a virtual
            (done) =>
              model.findByIdOrCreate req.params.document_id,
                text: """
                  VIRTUAL
                  This #{options.singular} is not saved or was removed.
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
          $ "%s %s", route.method, route.url
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
          $ "%s %s", route.method, route.url
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


      # remove            : 
      #   path              : "#{@options.root}/:document_id"
      #   method            : "DELETE"
      #   action            : (req, res) =>
      #     $ "%s %s", @actions.remove.method, @actions.remove.path
      #     $ "Removing %s", @options.singular

      # single_journal    : 
      #   path              : "#{@options.root}/:document_id/journal"
      #   method            : "GET"
      #   action            : (req, res) =>
      #     $ "%s %s", @actions.single_journal.method, @actions.single_journal.path
      #     $ "Getting journal entries about single %s", @options.singular

      single_draft      :
        method            : "GET"
        url               : root + "/:document_id/drafts/:draft_id"
        action            : (options, req, res) ->
          route = @routes.single_draft
          $ "%s %s", route.method, route.url
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
                console.dir res.locals
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
      #     $ "%s %s", @actions.single_entry.method, @actions.single_entry.path
      #     $ "Getting single journal entry about %s", @options.singular

      # list_references   : 
      #   path              : "#{@options.root}/:document_id/:reference_path/"
      #   method            : "GET"
      #   action            : (req, res) =>
      #     $ "%s %s", @actions.list_references.method, @actions.list_references.path
      #     $ "Getting list of %s referencing single %s", req.params.reference_path, @options.singular

      # single_reference  : 
      #   path              : "#{@options.root}/:document_id/:reference_path/:reference_id/"
      #   method            : "GET"
      #   action            : (req, res) =>
      #     $ "%s %s", @actions.single_reference.method, @actions.single_reference.path
      #     $ "Getting a single %s referencing single %s", req.params.reference_path, @options.singular

      # add_reference     : 
      #   path              : "#{@options.root}/:document_id/:reference_path/"
      #   method            : "POST"
      #   action            : (req, res) =>
      #     $ "%s %s", @actions.add_reference.method, @actions.add_reference.path
      #     $ "Adding new %s reference of single %s", req.params.reference_path, @options.singular

      # remove_reference  : 
      #   path              : "#{@options.root}/:document_id/:reference_path/"
      #   method            : "POST"
      #   action            : (req, res) =>
      #     $ "%s %s", @actions.remove_reference.method, @actions.remove_reference.path
      #     $ "Removing a single %s reference of single %s", req.params.reference_path, @options.singular
    
    # Default options are the same for all routes
    for name, route of routes
      route.options = 
        pre               : (req, res, done) -> process.nextTick -> done null
        post              : (req, res, done) -> process.nextTick -> done null

    console.dir options
    options.routes = _(routes).merge(options.routes).value()
    $ "Calling super with options: %j", options
    super options


  
