{
  renderable, tag, text
  div, main, aside, nav
  ul, li
  h3, h4, p
  i, span
  a
  form, button, input
  hr
} = require "teacup"
template  = require "./templates/default"

module.exports = renderable (data) ->
  helper = (name, context) =>
    fn = require "./helpers/" + name
    context ?= @
    fn.call context

  template.call @, =>   
    helper "search-form"
    helper "news-feed"



