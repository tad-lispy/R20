# Home controller

Story       = require "../../models/Story"
Entry       = require "../../models/JournalEntry"
Question    = require "../../models/Question"
Participant = require "../../models/Participant"
Controller  = require "express-controller"

debug       = require "debug"
$           = debug "R20:controllers:home"

views =
  index: require "../../views/home"

module.exports = new Controller
  name    : "home"
  routes  :
    display :
      method  : "GET"
      url     : "/"
      action  : (options, req, res) ->
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

            Participant.populate entries,
              path  : "data._draft.meta.author"
              model : "Participant"
              (error, entries) ->
                res.locals { entries }
               
                res.send views.index res.locals
