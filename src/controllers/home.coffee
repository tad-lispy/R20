# Home controller

Story = require "../models/Story"

module.exports = 
  get: (req, res) ->
    { query } = req.query
    res.locals { query }
    Story.find (error, stories) ->
      if error then throw error    
      
      res.locals.stories  = stories
      template            = require "../views/home"
      res.send template.call res.locals
