# # Journal plugin

debug     = require "debug"
_         = require "underscore"
mongoose  = require "mongoose"
async     = require "async"

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

  schema.add
    "_draft":
      type: mongoose.Schema.ObjectId
      ref : "journal.entry"


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

  schema.methods = 

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

    findEntries: (query, callback) ->
      if not callback and typeof query is "function" 
        callback  = query
        query     = {}
      
      query = _.extend query,
        "data._id": @_id

      Entry
        .find(query)
        .sort(_id: -1)
        .exec callback


    saveReference: (path, id, meta, callback) ->
      if not callback and typeof meta is "function" then callback = meta
      callback null

    applyReference: (id, callback) ->
      if not callback and typeof options is "function" then callback = options
      callback null

    dropReference: (id, callback) -> callback null

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






    

module.exports = plugin