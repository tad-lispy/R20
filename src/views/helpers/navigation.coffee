{
  renderable, text
  nav, ul, li,
  a, i
} = require "teacup"

module.exports = renderable ->
  nav class: "well sidebar-nav", =>
    ul class: "nav nav-pills nav-stacked", => for item in [
      title : "Start"
      url   : "/"
      icon  : "home"
    ,
      title : "About"
      url   : "/about"
      icon  : "group"
    ,
      title : "Log in"
      url   : "/authenticate"
      icon  : "ok-circle"
    ]
      li class: ("active" if item.url is @url), => a href: "#{item.url}", =>
        i class: "icon-fixed-width icon-#{item.icon}"
        text " " + item.title