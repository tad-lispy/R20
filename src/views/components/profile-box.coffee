View      = require "teacup-view"
_         = require "lodash"
_.string  = require "underscore.string"
debug     = require "debug"
$         = debug   "R20:views:helpers:profile-box"

module.exports = new View (options = {}) ->
  {
    participant
    _fake_login
  } = options
  @div class: "panel panel-default sidebar-nav", =>
    @nav class: "panel-body", =>
      if participant?
        @h5 participant.name
        @h6 participant.roles.join ", "
        unless _fake_login
          @ul class: "nav nav-pills nav-stacked", =>
            @li => @a href: "#!/logout", title: "Log out", =>
              @i class: "fa fa-fixed-width fa-power-off"
              @text " Log out"        
      else 
        unless _fake_login 
          @ul class: "nav nav-pills nav-stacked", =>
            @li => @a href: "#!/authenticate", title: "Log in", =>
              @i class: "fa fa-fixed-width fa-ok-circle"
              @text " Log in"
