# About controller

fs      = require "fs"
path    = require "path"

dir     = path.dirname require.main.filename
dir     = path.resolve dir, "../assets/"

text    = fs.readFileSync dir + "/about-pl.md", "utf-8"

module.exports = 
  get: (req, res) ->
    res.locals.about = { text }

    template = require "../views/about"
    res.send template.call res.locals