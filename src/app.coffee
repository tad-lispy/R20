do (require "source-map-support").install

express   = require "express"
path      = require "path"
_         = require "underscore"
_.string  = require "underscore.string"
mongoose  = require "mongoose"

app = do express

app.set "name",     "Radzimy.co"
app.set "motto",    "Podnosimy świadomość prawną."
app.set "engine",   "R20"
app.set "version",  (require "../package.json").version
app.set "repo",     (require "../package.json").repo

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

app.use (req, res, next) ->
  res.locals.settings = _(app.settings).pick [
    "name"
    "motto"
    "engine"
    "version"
    "repo"
    "env"
    "author"
  ]

  res.locals.url = req.url

  do next

app.use do express.favicon
app.use do express.bodyParser
app.use do express.methodOverride
app.use do express.logger

# Statics
app.use '/js', express.static 'assets/scripts/app'
app.use '/js', express.static 'assets/scripts/vendor'

app.use '/css', express.static 'assets/styles/app'
app.use '/css', express.static 'assets/styles/vendor'

# Load controllers
controllers = {}
for name in [
  "home"
  "search"
  "about"
  "story"
  "question"
]
  controller = require "./controllers/#{name}"
  controllers[name] = controller

  terms = [
    "get"
    "post"
    "put"
    "delete"
  ]

  # For each path defined in a controler set app[term] path = function
  # eg. app.get / (req, res) ->
  setup = (fragment, value, path = "") ->
    if (fragment in terms) and (typeof value is "function")
      path ?= "/"
      console.log "setting up: " + (_.string.rpad fragment, 8, ' ') + "\t" + path
      # console.log "app[#{fragment}] #{path}, #{typeof value}"
      app[fragment] path, value
    else 
      path += "/" + fragment
      if typeof value isnt "object" then throw Error  =  """
        Error loading #{name} controller for path #{path}.
        Only object or function with name indicating valid http method can be used in controllers.
      """

      for fragment, subvalue of value
        setup fragment, subvalue, path

  setup name, controller

app.get "/", (req, res) -> res.redirect "/home"

mongoose.connect "mongodb://localhost/R20"
app.listen "3210"