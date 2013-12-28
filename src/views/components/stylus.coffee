View    = require "teacup-view"
stylus  = require "stylus"

module.exports = new View (code) ->
  @style type: "text/css", stylus.render code