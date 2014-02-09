View      = require "teacup-view"
moment    = require "moment"
moment.lang "pl"

module.exports = new View (given, locale = 'pl') ->
  if      typeof given.getTimeStamp       is "function" then given = do given.getTimeStamp
  else if typeof given._id?.getTimeStamp  is "function" then given = do given._id.getTimeStamp

  @raw moment(given).fromNow()