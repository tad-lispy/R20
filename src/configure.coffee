debug     = require "debug"
$         = debug "R20:setup"

module.exports = (app, options) ->
  # Initial setup

  try
    $ "loading configuration file"
    config  = require "../config.json"
  catch e
    $ "Error: no configuration file in /config.json"
    $ e
    process.exit 1


  app.set key,        value for key, value of config
  app.set "engine",
    name:     "R20"
    version:  (require "../package.json").version
    repo:     (require "../package.json").repo

  author = (require "../package.json").author.match ///
    ^
    \s*
    ([^<\(]+)     # name
    \s+
    (?:<(.*)>)?   # e-mail
    \s*
    (?:\((.*)\))? # website
    \s*
  ///
  app.set "author",
    name    : do author[1]?.trim
    email   : do author[2]?.trim
    website : do author[3]?.trim
