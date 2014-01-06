# # Journal plugin

debug     = require "debug"
_         = require "underscore"
mongoose  = require "mongoose"
async     = require "async"
util      = require "util"

Entry     = require "./JournalEntry"

$ = debug "R20:journal:plugin"

deepOmit = (object, omit) ->
  for key, value of omit
    if object[key]? then switch typeof value
      when "object" 
        if typeof object[key] is "object"
          # Go deeper
          object[key] = deepOmit object[key], value
      
      when "function"
        # Do callback and delete if returns true
        if value object[key] then delete object[key]
      else 
        # Something else - if it's truthy then delete
        if value then delete object[key]

  return object


plugin = (schema, options) ->

  options = _.defaults options,
    omit  : {}

  # _draft field points to currently applied draft
  schema.add
    "_draft":
      type: mongoose.Schema.ObjectId
      ref : "Journal.Entry"

  # Discover paths with references
  $ = $.root.narrow "discover_references"
  schema.statics.references = {}

  schema.eachPath (path, description) ->
    { type } = description.options 
    if not type then return
    if util.isArray type
      relation = "has many"
      options  = type[0]
    else 
      relation = "has one"
      options  = description.options

    if options.ref?
      model = options.ref
      reference = { path, relation, model }
      $ "Found %j", reference
      schema.statics.references[path] = reference


  schema.statics.findByIdOrCreate = (id, data, callback) ->
    $ = $.root.narrow "find_by_id_or_create"
    if (not callback) and (typeof data is "function")
      callback  = data
      data      = {}
    # TODO: ability to return a promise if callback is absent

    data._id = id


    @findById id, (error, document) =>
      if error then return callback error
      $ = $.narrow "find_by_id"
      if not document then document = new @ data
      callback null, document

  schema.methods = _(schema.methods).extend

    saveDraft: (meta, callback) ->
      $ = $.narrow "save_draft"
      if not callback and typeof meta is "function" then callback = meta

      draft = do @.toObject
      model = @constructor.modelName

      
      # Don't store references and such.
      draft = deepOmit draft, options.omit

      entry = new Entry
        action: "draft"
        model : model
        data  : draft
        meta  : meta

      entry.save (error) ->
        callback error, entry

    saveReference: (path, document, meta, callback) ->
      if not callback and typeof meta is "function" 
        callback  = meta
        meta      = {}
      
      reference = @constructor.references[path]
      ref_model = document.constructor
      if ref_model.modelName isnt reference.model
        return callback Error "Reference model doesn't match document"
      
      entry = new Entry
        action: "reference"
        model : @constructor.modelName
        data  :
          reference : reference
          main      : @_id
          referenced: document._id 
        meta  : meta

      entry.save (error) ->
        if error then return callback error
        callback null, entry

    removeReference: (path, document, meta, callback) ->
      if not callback and typeof meta is "function" 
        callback  = meta
        meta      = {}

      reference = @constructor.references[path]

      entry = new Entry
        action: "unreference"
        model : @constructor.modelName
        data  : 
          reference : reference
          main      : @_id
          referenced: document
        meta  : meta

      entry.save (error) ->
        if error then return callback error
        callback null, entry
        

    removeDocument: (meta, callback) ->
      # Remove document from collection while preserving all drafts.
      # Snapshot of the document will be stored in a journal.
      $ = $.root.narrow "remove_document"

      entry = new Entry
        action: "remove"
        model : @constructor.modelName
        data  : do @toObject
        meta  : meta

      entry.save (error) =>
        if error then return callback error

        @remove (error) ->
          if error then return entry.remove (entry_error) ->
            $ "There was en error removing document. We have to remove entry now."
            if entry_error then throw entry_error # Shit!
            return callback error

          callback null, entry

    findEntries: (conditions, callback) ->
      if not callback and typeof conditions is "function" 
        callback    = conditions
        conditions  = {}
      
      _(conditions).extend conditions,
        model     : @constructor.modelName
        "data._id": @_id

      query = Entry
        .find(conditions)
        .sort(_id: -1)

      { populate } = options
      if populate?
        if typeof populate isnt "array" then populate = [ populate ]
        for spec in populate
          $ "Populating %s of %s with %s", spec.path, @constructor.modelName, spec.model
          query.populate spec
 
      query.exec callback

module.exports = plugin