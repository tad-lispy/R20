Story       = require "../../models/Story"
Entry       = require "../../models/JournalEntry"
Question    = require "../../models/Question"
Participant = require "../../models/Participant"

async       = require "async"
debug       = require "debug"
$           = debug "R20:controllers:home"

view        = require "../../views/home"

# Different population logic for different actions
# TODO: this should go to Entry model
populate = 
  reference   : (entry, done) ->
    main_model  = Entry.model entry.model
    ref_model   = Entry.model entry.data.reference.model
    async.parallel [
      (done) => main_model.populate entry, path: "data.main"      , done
      (done) => ref_model.populate  entry, path: "data.referenced", done
    ], done
  unreference : (entry, done) -> @reference entry, done
  apply       : (entry, done) ->
    switch entry.data._entry.action
      when "reference"    then @reference   entry.data._entry, done
      when "unreference"  then @unreference entry.data._entry, done
      when "draft"        then Participant.populate entry,
        path: "data._entry.meta.author"
        done
      else done null

module.exports =  (options, req, res) ->
  $ = $.narrow "get"
  { query } = req.query
  res.locals { query }
  Entry
    .find()
    .sort(_id: -1)
    .limit(10)
    .populate(
      path  : "meta.author"
      model : "Participant"
    )
    .populate(
      path  : "data._entry"
      model : "Journal.Entry"
    )
    .exec (error, entries) ->
      $ = $.narrow "find_entries"
      if error then throw error

      async.each entries,
        (entry, done) =>
          { action } = entry
          if populate[action]? then populate[action] entry, done 
          else process.nextTick -> done null
        (error) =>
          if error then throw error
          res.locals { entries }
          res.send view res.locals
          
