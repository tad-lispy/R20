{
  renderable, text
  nav, ul, li,
  h4, h5
  a, i
} = require "teacup"

module.exports = renderable ->

  nav class: "well sidebar-nav", =>
      if @session.email?
        h4 @session.email
        h5 @session.role
        ul class: "nav nav-pills nav-stacked", =>
          li => a href: "#!/logout", title: "Log out", =>
            i class: "icon-fixed-width icon-power-off"
            text " Log out"        
      else
        ul class: "nav nav-pills nav-stacked", =>
          li => a href: "#!/authenticate", title: "Log in", =>
            i class: "icon-fixed-width icon-ok-circle"
            text " Log in"