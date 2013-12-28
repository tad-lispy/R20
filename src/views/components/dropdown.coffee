View      = require "teacup-view"
_         = require "lodash"

module.exports = new View (options = {}) ->
  _.defaults options,
    items: []

  {
    items
  } = options

  @button
    class : "btn btn-default  dropdown-toggle"
    data  :
      toggle: "dropdown"
    =>
      @span class: "caret"
      @span class: "sr-only", "Toggle dropdown"

  @ul class: "dropdown-menu", role: "menu", =>
    @li => for item in items
      @a 
        href: item.href
        data: item.data
        =>
          @i class: "icon-" + item.icon or "cog"
          @text " " + item.title
