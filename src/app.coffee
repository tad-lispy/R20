do (require "source-map-support").install

console.log "Charging R20..."

express   = require "express"
path      = require "path"
_         = require "underscore"
_.string  = require "underscore.string"
async     = require "async"
mongoose  = require "mongoose"
request   = require "request"
debug     = require "debug"
$         = debug "R20"

app       = do express

configure = require "./configure"
configure app

# Middleware setup
$ = $.root.narrow ""

# Log each request:
app.use (req, res, next) ->
  $ = $.root.narrow "middleware:request"
  $ "\n\t%s\t%s", req.method, req.url
  do next

# app.use (req, res, next) ->
#   $ = $.narrow "home-redirect"
#   if req.url is "/" then res.redirect "/home"
#   else do next


# Make sure configuration is visible to middlewares and views
app.use (req, res, next) ->
  $ = $.root.narrow "middleware:settings"
  res.locals.settings = _(app.settings).pick [
    "name"
    "motto"
    "engine"
    "version"
    "repo"
    "env"
    "author"
    "site"
  ]

  do next

# Store expose url and helpers to middleware
app.use (req, res, next) ->
  $ = $.root.narrow "middleware:helpers"
  res.locals.url = req.url

  res.locals.helper = (name) =>
    return "No helping hand here"
    # fn = require "./views/helpers/" + name
    # fn.apply res.locals, (Array.prototype.slice.call arguments, 1)

  do next

# Technical stuff
app.use do express.bodyParser
app.use do express.cookieParser
app.use express.session secret: (app.get "site").secret or "Zdradzę wam dzisiaj potworny sekret. Jestem ciasteczkowym potworem!"
app.use do express.methodOverride

# Statics
$ = $.root.narrow "static"
app.use do express.favicon
app.use '/js', express.static 'assets/scripts/app'
app.use '/scripts', express.static 'scripts' # Coffeescript sources for debug
app.use '/js', express.static 'assets/scripts/vendor'

app.use '/css', express.static 'assets/styles/app'
app.use '/css', express.static 'assets/styles/vendor'

# Content Security Policy and other security related logic

# Most basic: make sure that only authenticated participants can post, put and delete:
app.use (req, res, next) ->
  $ = $.root.narrow "security:basic"
  $ "Check!"
  unless req.method.toLowerCase() in [
    "get"
    "head"
  ] or req.session?.email
    unless req.url is "/auth/login" and req.method.toLowerCase() is "post"
      $ "HALT!"  
      return next Error "Not authenticated"

  $ "It's OK for %s to %s.", req.session?.email, req.method
  do next

# Handle basic security errors
app.use (error, req, res, next) ->
  $ = $.root.narrow "middleware:error:security:basic"
  # See: http://stackoverflow.com/questions/7151487/error-handling-principles-for-nodejs-express-apps
  # TODO: implement this kind of error handling in other middlewares to
  if error.message is "Not authenticated"
    $ "Anonymous agent is trying to %s %s", req.method, req.url
    res.send 403, "Not authenticated"
  else 
    $ error.message
    next error


# Cross-site resource forgery prevention token:
app.use do express.csrf
# Expose it
app.use (req, res, next) ->
  res.locals.csrf = req.csrfToken()
  do next

# Handle csrf errors
app.use (error, req, res, next) ->
  $ = $.root.narrow "R20:middleware:error:csrf"
  # See: http://stackoverflow.com/questions/7151487/error-handling-principles-for-nodejs-express-apps
  # TODO: implement this kind of error handling in other middlewares to
  if error.status is 403
    $ "Apparently there was a csrf error: %j", error
    res.send 403
  else next error


# Content security policy
app.use (req, res, next) ->
  $ = $.root.narrow "middleware:csp"
  policy =  """
    default-src 'self' netdna.bootstrapcdn.com;
    frame-src 'self' https://login.persona.org;
    script-src 'self' 'unsafe-inline' https://login.persona.org ajax.googleapis.com cdnjs.cloudflare.com netdna.bootstrapcdn.com cdn.jsdelivr.net;
    style-src 'self' 'unsafe-inline' netdna.bootstrapcdn.com bootswatch.com
    font-src  'self' 'unsafe-inline' netdna.bootstrapcdn.com bootswatch.com
  """

  res.header "Content-Security-Policy",   policy
  res.header "X-Content-Security-Policy", policy
  res.header "X-WebKit-CSP",              policy
  res.header "X-UA-Compatible",           "IE=Edge"

  do next

# Session to locals
app.use (req, res, next) ->
  $ = $.root.narrow "session-to-locals"
  res.locals.session = req.session

  do next

# Authentication setup
$ = $.root.narrow "auth"

# Fake login while development
app.use (require "./middleware/fake-login")
  role: "Administrator"
  whitelist: (app.get "participants").whitelist

# Load participant profile
profile = require "./middleware/profile"
app.use profile participants: app.get "participants"


authenticate = (req, res, email, done) ->
  $ = $.narrow "authenticate"
  { whitelist } = app.get "participants"
  if whitelist 
    $ "There is a whitelist: %j", whitelist
    unless email of whitelist
      $ "%s not in the whitetelist %j", email, whitelist
      return done Error "Not in the whitelist"

    roles = whitelist[email].roles.join ", "
    $ "%s logged in as %s.",  email, roles
    req.session.email = email

    res.cookie "email", email
    do done
    
  else # no whitelist
    done Error "Not implemented yet."
    # throw Error "Open (non whitelist) authentication not implemented yet"


app.post "/auth/login", (req, res) ->
  $ = $.narrow "login"
  verifier =
      url   : (app.get "auth").verifier
      json  : true
      body  :
        assertion : req.body.assertion
        audience  : (app.get "auth").audience

  request.post verifier, (error, response, body) =>
    $ = $.narrow "verification"
    if error then throw error
    if body.status is "okay" then authenticate req, res, body.email, (error) ->
      if error 
        if error.message is "Not in the whitelist"
          # res.json 403, status: "forbiden"
        else throw error

      res.json status: "okay"

    else # Not okay :(
      $ "Login attempt failed. %j", { response, body }
      res.json 501, status: "failed"

app.post "/auth/logout", (req, res) ->
  $ = $.narrow "logout"
  $ "%s logging out.", req.session?.email

  if not req.session?.email?
    $ "Attempt to logout while not authenticated. "
    return res.json 403, status: "not logged in."

  req.session.destroy (error) ->
    $ = $.narrow "session_destroy"
    if error then throw error

    res.json status: "okay"
  
# Load controllers
$ = $.root.narrow "setup:controllers"

for name in [
  "home"
  "questions"
]
  $ "Loading %s controller", name
  controller = require "./controllers/#{name}"
  controller.plugInto app

app.use (error, req, res, next) ->
  $ = $.root.narrow "ultimate_error"
  $ "It happened :("
  throw error

do ->
port = 3210
mongo =
  host: "localhost"
  db  : "R20"
$ = $.root.narrow "start"
mongoose.connect "mongodb://#{mongo.host}/#{mongo.db}"
app.listen port

console.log "R20 is ready at :%s!", port