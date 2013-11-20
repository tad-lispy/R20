# Home controller

Story = require "../models/Story"
Entry = require "../models/JournalEntry"

module.exports = 
  get: (req, res) ->
    { query } = req.query
    res.locals { query }
    Entry.find (error, entries) ->
      if error then throw error    
      
      res.locals { entries }
      
      template = require "../views/home"
      res.send template.call res.locals
