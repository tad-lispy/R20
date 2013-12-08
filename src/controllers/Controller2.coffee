###

# Controller class

Constructor takes a model and options
constructs an object with actual controller logic in paths

TODO: Too long! Modularize.

TODO: Abstract it a bit more and modularize

Controller has following actions

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
  path: /question/
  list:
    pre : (req, res, options, done)            -> done error, options
    post: (req, res, options, documents, done) -> done error, documents
```

Options are passed to appropriate actions. Usualy options are functions to be called at a given stages of async.waterfall.

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

async     = require "async"
_         = require "underscore"
Entry     = require "../models/JournalEntry"

debug     = require "debug"
$         = debug "R20:Controller2"


class Controller
  constructor       : (@model, @options = {}) ->

    $ "New controller: %j", @options    
    _(@options).defaults
      singular  : do @model.modelName.toLowerCase
      plural    : @model.collection.name
      root      : "/" + do @model.modelName.toLowerCase

    $ "New controller: %j", @options

    @actions =
      list              : 
        path              : "#{@options.root}/"
        method            : "GET"
        main              : (req, res) =>
          action = @actions.list
          $ "%s %s", action.method, action.path
          $ "Getting list of %s", @options.plural
          async.waterfall [
            (done) => action.pre  req, res, done
            (done) =>
              @model.find res.locals.conditions, (error, documents) =>
                if error then return done error
                console.dir documents
                # res.locals[@options.plural] = documents
                done null
            (done) => action.post req, res, done
          ], (error) =>
            if error then throw error
            # if req.accepts ...

      new               : 
        path              : "#{@options.root}/"
        method            : "POST"
        main              : (req, res) =>
          $ "%s %s", @actions.new.method, @actions.new.path
          $ "Making new %s", @options.singular

      journal           : 
        path              : "#{@options.root}/journal"
        method            : "GET"
        main              : (req, res) =>
          $ "%s %s", @actions.journal.method, @actions.journal.path
          $ "Getting list of journal entries about %s", @options.plural

      single            : 
        path              : "#{@options.root}/:document_id"
        method            : "GET"
        main              : (req, res) =>
          $ "%s %s", @actions.single.method, @actions.single.path
          $ "Getting single %s", @options.singular

      update            : 
        path              : "#{@options.root}/:document_id"
        method            : "PUT"
        main              : (req, res) =>
          $ "%s %s", @actions.update.method, @actions.update.path
          $ "Updating %s", @options.singular

      remove            : 
        path              : "#{@options.root}/:document_id"
        method            : "DELETE"
        main              : (req, res) =>
          $ "%s %s", @actions.remove.method, @actions.remove.path
          $ "Removing %s", @options.singular

      single_journal    : 
        path              : "#{@options.root}/:document_id/journal"
        method            : "GET"
        main              : (req, res) =>
          $ "%s %s", @actions.single_journal.method, @actions.single_journal.path
          $ "Getting journal entries about single %s", @options.singular

      single_entry      : 
        path              : "#{@options.root}/:document_id/journal/:entry_id"
        method            : "GET"
        main              : (req, res) =>
          $ "%s %s", @actions.single_entry.method, @actions.single_entry.path
          $ "Getting single journal entry about %s", @options.singular

      list_references   : 
        path              : "#{@options.root}/:document_id/:reference_path/"
        method            : "GET"
        main              : (req, res) =>
          $ "%s %s", @actions.list_references.method, @actions.list_references.path
          $ "Getting list of %s referencing single %s", req.params.reference_path, @options.singular

      single_reference  : 
        path              : "#{@options.root}/:document_id/:reference_path/:reference_id/"
        method            : "GET"
        main              : (req, res) =>
          $ "%s %s", @actions.single_reference.method, @actions.single_reference.path
          $ "Getting a single %s referencing single %s", req.params.reference_path, @options.singular

      add_reference     : 
        path              : "#{@options.root}/:document_id/:reference_path/"
        method            : "POST"
        main              : (req, res) =>
          $ "%s %s", @actions.add_reference.method, @actions.add_reference.path
          $ "Adding new %s reference of single %s", req.params.reference_path, @options.singular

      remove_reference  : 
        path              : "#{@options.root}/:document_id/:reference_path/"
        method            : "POST"
        main              : (req, res) =>
          $ "%s %s", @actions.remove_reference.method, @actions.remove_reference.path
          $ "Removing a single %s reference of single %s", req.params.reference_path, @options.singular

    $ "Actions: %j", @actions
    for name, action of @actions
      $ "Setting pre and post for %s", name
      do ->
        action_name = name
        # Called before anything else
        action.pre          = (req, res, done) =>
          $ "Pre %s", action_name
          process.nextTick -> done null
        # Called right before sending response
        action.post         = (req, res, done) =>
          $ "Post %s", action_name
          process.nextTick -> done null

      $ "Looking for %s options", name

      if @options[name]? 
        $ "Setting %s to %j", name, @options[name]
        _.extend action, @options[name]

module.exports = Controller
  
