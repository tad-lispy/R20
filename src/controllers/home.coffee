# Home controller

Story       = require "../models/Story"
Entry       = require "../models/JournalEntry"
# Participant = require "../models/Participant"

debug = require "debug"
$     = debug "R20:controllers:home"

module.exports = 
  get: (req, res) ->
    $ = $.narrow "get"
    { query } = req.query
    res.locals { query }
    Entry
      .find()
      .sort(_id: -1)
      .limit(10)
      .populate("data._draft")
      .populate(
        path  : "meta.author"
        model : "Participant"
      )
      .populate(
        path  : "data.main_doc"
        model : "Story"
      )
      .populate(
        path  : "data.referenced_doc"
        model : "Question"
      )
      .exec (error, entries) ->
        $ = $.narrow "find_entries"
        if error then throw error
        
        res.locals { entries }
        
        template = require "../views/home"
        res.send template.call res.locals
