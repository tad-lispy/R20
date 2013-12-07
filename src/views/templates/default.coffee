{ 
  renderable, tag, text
  doctype, html, head, body
  title, meta, link, script, style
  header, main, footer, main, aside, div
  h1, h2, p
  a, i, small
  br, wbr
}       = require "teacup"

debug   = require "debug"
$       = debug "R20:templates:default"

stylus  = (code) ->
  style type: "text/css", "\n" + (require "stylus").render code

module.exports = renderable (content) ->  
  @scripts  ?= []
  @styles   ?= []

  doctype 5
  html =>
    head =>
      title @settings.name
      meta charset: "utf-8"
      meta name: "viewport", content: "width=device-width, initial-scale=1.0"

      link rel: "stylesheet", href: url for url in [
        "//netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css"
        "//netdna.bootstrapcdn.com/font-awesome/3.2.1/css/font-awesome.min.css"
      ]
      stylus """
        footer
          white-space nowrap

        .page-header
          h1
            white-space wrap
      """
        

    body data: csrf: @_csrf, =>
      div class: "container", id: "content", =>
        header class : "page-header", =>
          h1 =>
            text @settings.site.name + " "
            br class: "visible-xs visible-sm"
            small @page?.title or @settings.site.motto

        div class: "row", =>
          tag "main", class: "col-xs-12 col-sm-9", =>
            # button 
            #   type  : "button"
            #   class : "btn btn-lg visible-xs pull-right"
            #   data  : toggle: "offcanvas"
            #   => i class: "icon-expand-alt"

            do content

          aside
            id    : "sidebar"
            class : "con-xs-12 col-sm-3 sidebar-offcanvas"
            =>
              @helper "navigation"
              @helper "profile-box"

      footer class: "container", =>
        small =>
          i class: "icon-bolt"
          text " powered by "
          a
            href  : @settings.engine.repo
            target: "_blank"
            @settings.engine.name
          text " v. #{@settings.engine.version}. "
          do wbr
          text "#{@settings.engine.name} is "
          a 
            href: "/license",
            "a free software"
          text " by "
          a href: @settings.author?.website, @settings.author?.name
          text ". "
          do wbr
          text "Thank you :)"

      # views and controllers can set @styles and @scripts to be appended here
      script type: "text/javascript", src: url for url in [
        "//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"
        "//netdna.bootstrapcdn.com/bootstrap/3.0.0/js/bootstrap.min.js"
        "//cdnjs.cloudflare.com/ajax/libs/typeahead.js/0.9.3/typeahead.min.js"
        "//cdnjs.cloudflare.com/ajax/libs/mousetrap/1.4.5/mousetrap.min.js"
        "/js/keyboard-shortcuts.js"
        "//cdn.jsdelivr.net/jquery.cookie/1.4.0/jquery.cookie.min.js"
        "https://login.persona.org/include.js"
        "/js/authenticate.js"
        "/js/modals.js"
      ].concat @scripts or []

      if @styles? then link rel: "stylesheet", href: url for url in @styles
