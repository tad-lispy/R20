module.exports = (req, res, done) ->
      { query } = req.query
      res.locals.conditions = text: new RegExp query, "i"
      res.locals { query } 
      done null