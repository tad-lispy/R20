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
    $ "Going"
    if req.session?.email?
      $ "Loading profile"

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
