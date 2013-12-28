View      = require "teacup-view"
marked    = require "marked"
debug     = require "debug"
$         = debug "R20:helpers:markdown"

marked.setOptions
  breaks      : true
  sanitize    : true
  smartypants : true

module.exports = new View (content) -> @raw marked content