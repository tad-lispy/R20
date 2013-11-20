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
      $ = $.narrow "applyDraft"

      if not callback and typeof meta is "function" then callback = meta
      
      async.waterfall [
        (done) =>
          $ = $.narrow "findDraft"
          Entry.findById id, (error, draft) ->
            if error then return done error
            if not draft or draft.action isnt "draft" then return done Error "Draft not found"

            $ "Draft found: %j", draft
            done null, draft

        (draft, done) =>
          $ = $.narrow "applyToDocument"
          $ "#{draft.model} = #{@constructor.modelName}"
          $ "#{draft.data._id} = #{@_id}"

          if draft.model isnt @constructor.modelName or
             not draft.data._id.equals @_id then return done Error "Draft doesn't match document"

          $ "No error!"
          document = _(@).extend  draft.data
          document._draft   = draft._id
          $ "Story applied with draft: %j", document
          done null, document, draft
      ], (error, document, draft) =>
        if error then return callback error
        document.save (error) ->
          $ = $.narrow "saveDocument"
          if error then return callback error
          entry = new Entry
            action: "apply"
            model : document.constructor.modelName
            data  :
              _id   : @_id
              _draft: draft._id
            meta  : meta
          entry.save (error) ->
            $ = $.narrow "saveEntry"
            if error then callback error
            callback null, @

    saveReference: (path, id, meta, callback) ->
      if not callback and typeof meta is "function" then callback = meta
      callback null

    applyReference: (id, callback) ->
      if not callback and typeof options is "function" then callback = options
      callback null

    dropReference: (id, callback) ->



    

module.exports = plugin