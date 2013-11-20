# # Journal plugin

debug     = require "debug"
_         = require "underscore"
mongoose  = require "mongoose"

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

  schema.add
    "_draft":
      type: mongoose.Schema.ObjectId
      ref : "journal.entry"

  options = _.defaults options,
    omit  : {}

  schema.methods = 

    saveDraft: (meta, callback) ->
      $ = $.narrow "storeVersion"
      if not callback and typeof meta is "function" then callback = meta

      draft = do @.toObject
      model = @constructor.modelName

      
      # Do ont store references
      draft = deepOmit draft, options.omit

      entry = new Entry
        action: "draft"
        model : model
        data  : draft
        meta  : meta

      entry.save (error) ->
        $ "Draft for %s # %s saved as # %s.",  model, draft._id, entry._id
        callback error, entry

    findDrafts: (query, callback) ->
      if not callback and typeof query is "function" 
        callback  = query
        query     = {}
      
      query = _.extend query,
        action    : "draft"
        "data._id": @_id

      $ "Looking for drafts wher %j", query

      Entry.find query, callback

    applyDraft: (id, meta, callback) ->
      callback null
      if draft.model isnt schema.modelName or
        draft.data._id isnt req.params.id then return done Error "Draft doesn't match "


    saveReference: (path, id, meta, callback) ->
      if not callback and typeof meta is "function" then callback = meta
      callback null

    applyReference: (id, callback) ->
      if not callback and typeof options is "function" then callback = options
      callback null

    dropReference: (id, callback) ->



    

module.exports = plugin