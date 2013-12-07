{
  renderable, text
  div, nav, ul, li,
  a, i
} = require "teacup"

module.exports = renderable ->
  items = [
    title   : "Start"
    url     : "/"
    icon    : "home"
    shortcut: "g h"
  ,
    title   : "Stories"
    url     : "/story"
    icon    : "comment"
    shortcut: "g s"
  ,
    title   : "Questions"
    url     : "/question"
    icon    : "puzzle-piece"
    shortcut: "g q"
  ,
    title   : "About"
    url     : "/about"
    icon    : "group"
    shortcut: "g a"

  ]

  div class: "panel panel-default sidebar-nav", =>
    nav class: "panel-body", =>
      ul class: "nav nav-pills nav-stacked", =>
        for item in items
          li class: ("active" if item.url is @url), => 
            a 
              href: "#{item.url}"
              data: shortcut: item.shortcut
              =>
                i class: "icon-fixed-width icon-#{item.icon}"
                text " " + item.title