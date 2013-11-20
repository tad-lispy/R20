###

JournalEntry model
=============

Journal stores entries that describe changes to the states of documents in other collections. Those states can be used as a history of changes or collection of drafts. They can be applied to documents.

###

mongoose  = require "mongoose"
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

module.exports = mongoose.model "journal.entry", Entry