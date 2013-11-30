do (require "source-map-support").install

express   = require "express"
path      = require "path"
_         = require "underscore"
_.string  = require "underscore.string"
async     = require "async"
mongoose  = require "mongoose"
request   = require "request"
debug     = require "debug"
$         = debug "R20"

app = do express

configure = require "./configure"
configure app

# Middleware setup
$ = $.root.narrow ""

# Log each request:
app.use (req, res, next) ->
  $ = $.root.narrow "middleware:request"
  $ "\n\t%s\t%s", req.method, req.url
  do next

app.use (req, res, next) ->
  $ = $.narrow "home-redirect"
  if req.url is "/" then res.redirect "/home"
  else do next


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
    fn = require "./views/helpers/" + name
    fn.apply res.locals, (Array.prototype.slice.call arguments, 1)

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
app.use '/js', express.static 'assets/scripts/vendor'

app.use '/css', express.static 'assets/styles/app'
app.use '/css', express.static 'assets/styles/vendor'

# Content Security Policy and other security related logic

# Most basic: make sure that only authenticated participants can post, put and delete:
app.use (req, res, next) ->
  $ = $.root.narrow "security:basic"
  if req.method in [
    "post"
    "put"
    "delete"
  ] and not req.session?.email
    return next Error: "Not authenticated" unless req.url is "/auth/login" and req.method is "post"

  do next

# Cross-site resource forgery prevention token:
app.use do express.csrf
# Expose it
app.use (req, res, next) ->
  csrf = req.csrfToken()
  res.locals._csrf = csrf
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
    style-src 'self' 'unsafe-inline' netdna.bootstrapcdn.com
    font-src  'self' 'unsafe-inline' netdna.bootstrapcdn.com
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

# Load participant profile
Participant = require "./models/Participant"
app.use (req, res, next) ->
  $ = $.root.narrow "profile"
  $ "Going"
  if req.session?.email?
    $ "Loading profile"

    { 
      roles
      whitelist
      anonymous
    }         = app.get "participants"
    { email } = req.session
    
    async.waterfall [
      (done)              ->
        # Find profile
        $ "Looking"
        Participant.findOne { email }, done
      
      (participant, done) ->
        # Create new if necessary
        $ "Are we there?"
        if participant 
          $ "Found %j", participant
          done null, participant
        
        else
          $ "Not found. Making one up!"
          config = app.get "participants"
          if email of whitelist then data = whitelist[email]
          else data = anonymous
          data.email = email

          participant = new Participant data
          done null, participant

          # participant.save done

      (participant, done) ->
        # Set default role and capabilities
        if not participant.roles.length 
          role = _(roles).keys()[0]
          participant.roles.push [ role ]

        capabilities = {}
        for role in participant.roles
          for name, value of roles[role]
            capabilities[name] = capabilities[name] or value

        $ "Role capabilities are %j", capabilities
        
        _(participant.can).defaults capabilities

        done null, participant
        
      (participant, done) ->
        $ "Profile is %j", participant
        res.locals.participant = do participant.toObject
        $ "Done."
        do done
    ], next
  else
    $ "Not logged in. Done."
    do next

# Authentication setup
$ = $.root.narrow "auth"

# Fake login while development
# TODO: get rid of it in production!
fakeLogin = (options) ->
  (req, res, next) ->
    $ = $.narrow "fake-login"
    return do next unless (
      (process.env.NODE_ENV is "development") and
      (not req.session?.participant?)
    )

    { email, role } = options
    $ "Doing it for %s!", email or role
    { whitelist } = app.get "participants"
    if (not email) and whitelist # If email is not set, then role is required
      $ "Looking up whitelist for first %s", role
      email = _.chain(whitelist).keys().find((e) -> whitelist[e].role is role).value()

    if email then authenticate req, res, email, next
    else 
      $ "Email not found. Authenticating example user."
      authenticate "admin@example.com", next

# app.use fakeLogin role: "Administrator"
# Broken. It seems navigator.id is too smart for that :)
# Probabilly you would have to disable it if fake login happens.
# Too much fuss.

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
    $ = $.root.narrow "setup:controllers" + path.replace /\//g, ":"

    if (fragment in terms) and (typeof value is "function")
      path ?= "/"
      $ fragment
      app[fragment] path, value
      
    else 
      if typeof value isnt "object" then throw Error  =  """
        Error loading #{name} controller for path #{path}.
        Only object or function with name indicating valid http method can be used in controllers.
      """

      path += "/" + fragment
      for fragment, subvalue of value
        setup fragment, subvalue, path

  setup name, controller.paths or controller

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
$ "R20 is ready!"