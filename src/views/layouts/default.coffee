View    = require "teacup-view"

_       = require "lodash"
debug   = require "debug"
$       = debug "R20:templates:default"

module.exports = new View 
  components: __dirname + "/../components"
  (options = {}, content) ->  
    if not content and typeof options is "function"
      content = options
      options = {}

    _(options).defaults
      scripts : []
      styles  : []
      classes : []
      title   : "Radzimy.co"
      subtitle: "Prawo po ludzku"

    {
      scripts
      styles
      classes
      title
      subtitle
      settings
      csrf
      participant
      _fake_login
    } = options

    @doctype 5
    @html =>
      @head =>
        @title "#{title} | #{subtitle}"
        @meta charset: "utf-8"
        @meta name: "viewport", content: "width=device-width, initial-scale=1.0"

        @link rel: "stylesheet", href: url for url in [
          "//netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css"
          "//netdna.bootstrapcdn.com/font-awesome/4.0.3/css/font-awesome.min.css"
          "/css/r20.css"
        ]          

      @body data: { csrf }, class: (classes.join " "), =>
        @div class: "container", id: "content", =>
          @header class : "page-header", =>
            @h1 =>
              @text title + " "
              @br class: "visible-xs visible-sm"
              @small subtitle

          @div class: "row", =>
            @tag "main", class: "col-xs-12 col-sm-9", =>
              # button 
              #   type  : "button"
              #   class : "btn btn-lg visible-xs pull-right"
              #   dat@a  : toggle: "offcanvas"
              #   => @i class: "fa fa-expand-alt"

              do content

            @aside
              id    : "sidebar"
              class : "col-xs-12 col-sm-3"
              =>
                do @navigation
                @profileBox {participant, _fake_login}

        @footer class: "container", =>
          @small =>
            @i class: "fa fa-bolt"
            @text " powered by "
            @a
              href  : settings.engine.repo
              target: "_blank"
              settings.engine.name
            @text " v. #{settings.engine.version}. "
            do @wbr
            @text "#{settings.engine.name} is "
            @a 
              href: "/license",
              "a free software"
            @text " by "
            @a href: settings.author?.website, settings.author?.name
            @text ". "
            do @wbr
            @text "Thank you :)"

        # views and controllers can set @styles and @scripts to be appended here
        @script type: "text/javascript", src: url for url in [
          "//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"
          "//netdna.bootstrapcdn.com/bootstrap/3.0.0/js/bootstrap.min.js"
          "//cdnjs.cloudflare.com/ajax/libs/typeahead.js/0.9.3/typeahead.min.js"
          "//cdnjs.cloudflare.com/ajax/libs/mousetrap/1.4.5/mousetrap.min.js"
          "/js/keyboard-shortcuts.js"
          "//cdn.jsdelivr.net/jquery.cookie/1.4.0/jquery.cookie.min.js"
          "https://login.persona.org/include.js"
          "/js/authenticate.js"
          "/js/modals.js"
        ].concat scripts or []

        if @styles? then @link rel: "stylesheet", href: url for url in @styles
