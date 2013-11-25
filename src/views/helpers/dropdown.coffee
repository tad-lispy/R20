{
  renderable, text
  ul, li,
  a, i, button, span
} = require "teacup"

module.exports = renderable (items) =>

  button
    class : "btn btn-default  dropdown-toggle"
    data  :
      toggle: "dropdown"
    =>
      span class: "caret"
      span class: "sr-only", "Toggle dropdown"

  ul class: "dropdown-menu", role: "menu", =>
    li => for item in items
      a 
        href: item.href
        data: item.data
        =>
          i class: "icon-" + item.icon or "cog"
          text " " + item.title
