# Search controller

_       = require "underscore"

module.exports = 
  post: (req, res) ->
    res.locals.search = _(req.body).pick [
      "query"
    ]
    res.locals.search.results = ({
      url   : "##{i}"
      type  : "question"
      title : "Czy #{req.body.query} #{i}?"
    } for i in [1..12])

    template = require "../views/search"
    res.send template.call res.locals
