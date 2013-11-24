{
  renderable
  raw
}         = require "teacup"
marked    = require "marked"
debug     = require "debug"

$         = debug "R20:helpers:markdown"

marked.setOptions
  breaks      : true
  sanitize    : true
  smartypants : true

module.exports = (content) -> raw marked content