{
  renderable, text
  nav, ul, li,
  a, i
} = require "teacup"

module.exports = renderable ->
  items = [
    title : "Start"
    url   : "/"
    icon  : "home"
  ,
    title : "About"
    url   : "/about"
    icon  : "group"
  ,
    title : "Questions"
    url   : "/question"
    icon  : "puzzle-piece"
  ]

  nav class: "well sidebar-nav", =>
    ul class: "nav nav-pills nav-stacked", =>
      for item in items
        li class: ("active" if item.url is @url), => a href: "#{item.url}", =>
          i class: "icon-fixed-width icon-#{item.icon}"
          text " " + item.title