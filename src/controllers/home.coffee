# Home controller

Story = require "../models/Story"
Entry = require "../models/JournalEntry"

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
      .populate("data._draft")
      .exec (error, entries) ->
        $ = $.narrow "find_entries"
        if error then throw error
        
        res.locals { entries }
        
        template = require "../views/home"
        res.send template.call res.locals
