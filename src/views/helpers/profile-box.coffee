{
  renderable, text
  div, nav, ul, li,
  h5, h6
  a, i
} = require "teacup"

module.exports = renderable ->

  div class: "panel panel-default sidebar-nav", =>
    nav class: "panel-body", =>
      if @session.email?
        h5 @session.email
        h6 @session.role
        ul class: "nav nav-pills nav-stacked", =>
          li => a href: "#!/logout", title: "Log out", =>
            i class: "icon-fixed-width icon-power-off"
            text " Log out"        
      else
        ul class: "nav nav-pills nav-stacked", =>
          li => a href: "#!/authenticate", title: "Log in", =>
            i class: "icon-fixed-width icon-ok-circle"
            text " Log in"