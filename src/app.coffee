do (require "source-map-support").install

express   = require "express"
path      = require "path"
_         = require "underscore"
_.string  = require "underscore.string"
mongoose  = require "mongoose"
request   = require "request"
debug     = require "debug"
$         = debug "R20"

app = do express

do -> # Initial setup
  $ = debug "R20:setup"

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

do -> # Middleware setup
  $ = $.narrow "middleware"

  app.use (req, res, next) ->
    $ = $.narrow "first"
    $ "\n\t%s\t%s", req.method, req.url
    do next

  app.use (req, res, next) ->
    $ = debug "R20:middleware:settings"
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

    res.locals.url = req.url
    res.locals.helper = (name) =>
      fn = require "./views/helpers/" + name
      fn.apply res.locals, (Array.prototype.slice.call arguments, 1)


    do next


  app.use do express.bodyParser
  app.use do express.cookieParser
  app.use express.session secret: (app.get "site").secret or "Zdradzę wam dzisiaj potworny sekret. Jestem ciasteczkowym potworem!"

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
        email = _.chain(whitelist).keys().find((e) -> whitelist[e] is role).value()

      if email then app.authenticate req, res, email, next
      else 
        $ "Email not found. Authenticating example user."
        app.authenticate "admin@example.com", next

  # app.use fakeLogin email: "piotrmarekpaszkowski@gmail.com"

  app.authenticate = (req, res, email, done) ->
    { whitelist } = app.get "participants"
    if whitelist 
      $ "There is a whitelist: %j", whitelist
      unless email of whitelist
        $ "%s not in the whitetelist %j", email, whitelist
        return done Error "Not in the whitelist"

      role = whitelist[email]
      $ "%s logged in as %s.",  email, role
      req.session.email = email
      req.session.role  = role

      res.cookie "email", email
      do done
      
    else # no whitelist
      done Error "Not implemented yet."
      # throw Error "Open (non whitelist) authentication not implemented yet"


  app.use (req, res, next) ->
    $ = debug "R20:middleware:session-to-locals"
    $ "Rewriting session data to "
    res.locals.session = req.session
    do next

  app.use do express.favicon
  app.use do express.methodOverride

do -> # Content Security Policy and other security related logic
  $ = debug "R20:setup:security"
  app.use do express.csrf
  app.use (error, req, res, next) ->
    $ = debug "R20:middleware:error:csrf"
    # See: http://stackoverflow.com/questions/7151487/error-handling-principles-for-nodejs-express-apps
    # TODO: implement this kind of error handling in other middlewares to
    if error.status is 403
      $ "Apparently there was a csrf error: %j", error
      res.send 403
    else next error


  app.use (req, res, next) ->
    $ = debug "R20:middleware:csp"
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

    csrf = req.csrfToken()
    $ "Setting csrf tocken to %s", csrf 
    res.locals._csrf = csrf

    do next

do -> # Authentication setup
  $ = $.root.narrow "auth"

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
      if body.status is "okay" then app.authenticate req, res, body.email, (error) ->
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
      $ "done"
      res.json status: "okay"

do -> # Make sure that only authenticated users can post, put and delete:
  $ = debug "R20:setup:privileges:basic"
  for verb in [
    "post"
    "put"
    "delete"
  ]
    app[verb] "*", (req, res, next) ->
      if req.session.email or req.url is "/auth/login" then do next 
      else res.send 403

do -> # Statics
  $ = debug "R20:setup:static"
  app.use '/js', express.static 'assets/scripts/app'
  app.use '/js', express.static 'assets/scripts/vendor'

  app.use '/css', express.static 'assets/styles/app'
  app.use '/css', express.static 'assets/styles/vendor'

do -> # Load controllers\
  $ = debug "R20:setup:controllers"
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
      $ = $ = debug "R20:setup:controllers" + path.replace /\//g, ":"

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

app.get "/", (req, res) ->
  $ = debug "R20:home-redirect"
  res.redirect "/home"

do ->
  port = 3210
  mongo =
    host: "localhost"
    db  : "R20"
  $ = debug "R20:setup:start"
  mongoose.connect "mongodb://#{mongo.host}/#{mongo.db}"
  app.listen port
  $ "R20 is ready!"