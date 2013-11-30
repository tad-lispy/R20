# # Fake login middleware factory
# To be used in development only

_     = require "underscore"
debug = require "debug"
$     = debug "R20:fake-login"

module.exports = (options) ->
  { 
    email
    role
    whitelist
  } = options

  if not email
    $ "Looking up whitelist for first %s", role
    if role and whitelist
      email = _.chain(whitelist)
        .keys()
        .find(
          (e) -> role in whitelist[e].roles
        ).value()
      $ "It's %s", email
    else
      email = "user@example.com"
  

  (req, res, next) ->
    return do next unless (
      (process.env.NODE_ENV is "development") and
      (not req.session?.participant?)
    )

    $ "Doing it for %s!", email
    req.session.email       = email
    res.locals._fake_login  = true
    do next

