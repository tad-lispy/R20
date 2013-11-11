{
  renderable, tag, text, raw
  div, main, aside, nav
  ul, li
  h3, h4, p
  i, span
  a
  form, button, input
  hr
}         = require "teacup"
template  = require "./templates/aside"
marked    = require "marked"


module.exports = renderable (data) ->
  template.call @, =>   
    raw marked @about.text



