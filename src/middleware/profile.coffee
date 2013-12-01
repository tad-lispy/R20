# # Profile middleware
# Prepare profile and propagate it to res.locals

async = require "async"
_     = require "underscore"
debug = require "debug"
$     = debug "R20:middleware:profile"

Participant = require "../models/Participant"

module.exports = (options) ->
  { 
    roles
    whitelist
    anonymous
  }         = options.participants
  # TODO: calculate roles capabilities based on "as" keyword, eg:
  # Prawnik:
  #   "as"              : "Czytelnik"
  #   "answer questions": true

  return (req, res, next) ->
    $ = $.root.narrow "profile"
    if req.session?.email?
      { email } = req.session
      $ "Loading profile of %s", email

      async.waterfall [
        (done)              ->
          # Find profile
          Participant.findOne { email }, done
        
        (participant, done) ->
          # Create new if necessary
          if participant 
            done null, participant
          
          else
            $ "Not found. Making one up!"
            if email of whitelist then data = whitelist[email]
            else data = anonymous
            data.email = email

            participant = new Participant data
            

            # TODO: don't save. 
            #   done null, participant
            # In the end:
            #   if participant.isNew then res.redirect "/profile"
            participant.save -> done null, participant

        (participant, done) ->
          # Set default role and capabilities
          if not participant.roles.length 
            participant.roles  = anonymous.roles

          capabilities = {}
          for role in participant.roles
            for name, value of roles[role]
              capabilities[name] = capabilities[name] or value
          
          _(participant.can).defaults capabilities

          done null, participant
          
        (participant, done) ->
          res.locals.participant = do participant.toObject
          do done
      ], next
    else
      $ "Not logged in. Done."
      do next
