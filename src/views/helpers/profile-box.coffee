{
  renderable, text
  div, nav, ul, li,
  h5, h6
  a, i
}         = require "teacup"
_         = require "underscore"
_.string  = require "underscore.string"
debug     = require "debug"
$         = debug   "R20:views:helpers:profile-box"

module.exports = renderable ->
  div class: "panel panel-default sidebar-nav", =>
    nav class: "panel-body", =>
      if @participant?
        h5 @participant.name
        h6 @participant.roles.join ", "
        unless @_fake_login
          ul class: "nav nav-pills nav-stacked", =>
            li => a href: "#!/logout", title: "Log out", =>
              i class: "icon-fixed-width icon-power-off"
              text " Log out"        
      else 
        unless @_fake_login 
          ul class: "nav nav-pills nav-stacked", =>
            li => a href: "#!/authenticate", title: "Log in", =>
              i class: "icon-fixed-width icon-ok-circle"
              text " Log in"