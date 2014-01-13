debug     = require "debug"
$         = debug "R20:setup"

module.exports = (app, options) ->
  # Initial setup

  try
    $ "loading configuration file"
    config  = require "../config.json"
  catch e
    console.log """
      It seems there is no configuration file in /config.json yet.
      I'll create one for you now.
    """

    crypto  = require "crypto" 
    path    = require "path"
    fs      = require "fs"

    config =
      auth        :
        verifier    : "https://verifier.login.persona.org/verify",
        audience    : "http://r20.example.com/"
      participants:
        roles       :
          Reader        :
            "create a story"  : yes
            "edit own profile": yes
          Editor        :
            "as"              : "reader"
            "draft a story"   : yes
          Administrator :
            "everything"      : yes

        anonymous   :
          name        : "Anonymous"
          roles       : [ "reader" ]

        whitelist   :
          "user@example.com":
            name              : "Example User"
            roles             : [ "Administrator" ]

      site        :
        name        : "New R20 Website"
        motto       : "where config.json wasn't edited yet",

    buffer  = crypto.randomBytes 256
    hex     = buffer.toString 'hex'
    config.site.secret = hex

    json  = JSON.stringify config, null, 2
    file  = path.resolve __dirname, "../config.json"
    console.log json
    console.log "Saving to #{file}"

    fs.writeFileSync file, json


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
