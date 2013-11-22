###

JournalEntry model
=============

Journal stores entries that describe changes to the states of documents in other collections. Those states can be used as a history of changes or collection of drafts. They can be applied to documents.

###

mongoose  = require "mongoose"
async     = require "async"
_         = require "underscore"
debug     = require "debug"

$         = debug "R20:models:journal"

Entry = new mongoose.Schema
  
  action    : # What happened?
    type      : String
    required  : yes
    validate  : (value) -> value in [
      "draft"     # New draft
      "apply"     # Draft applied
      "remove"    # Document removed
      "reference" # Reference to subdocument proposed
      "drop"      # Drop applied change (only reference ATM)
    ]

  model     : # Where?
    type      : String
    required  : yes

  data      : # What's the effect?
    type      : Object
    required  : yes

  meta      :
    type      : Object

Entry.method "apply", (meta, callback) ->
  $ = $.narrow "apply"
  $ "Applying entry %s"

  if not callback and typeof meta is "function" then callback = meta

  try
    model = @constructor.model @model
  catch error
    return callback error

  switch @action
    when "draft"
      $ = $.narrow "draft"

      async.waterfall [
        (done) =>
          $ = $.narrow "get_document"

          model.findById @data._id, (error, document) ->
            if error then return done error
            
            if not document then document = new model

            done null, document

        (document, done) =>
          $ = $.narrow "copy_data"

          _(document).extend  @data
          document._draft   = @_id

          done null, document
      ], (error, document) =>
        if error then return callback error
        
        document.save (error) =>
          $ = $.narrow "save_document"
          if error then return callback error
          entry = new @.constructor
            action: "apply"
            model : model.modelName
            data  :
              _id   : document._id
              _draft: @_id
            meta  : meta
          entry.save (error) ->
            $ = $.narrow "new_entry"
            if error then callback error
            callback null, document

    else return callback Error "Journal entry not applicable"

module.exports = mongoose.model "journal.entry", Entry