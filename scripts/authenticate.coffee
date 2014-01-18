$ ->
  csrf = $('body').data 'csrf'
  navigator.id.watch {
    loggedInUser: ($.cookie "email") or null
    onlogin     : (assertion) ->
      xhr = $.post "/auth/login",
        assertion : assertion
        _csrf: csrf
        (data) ->
          console.dir data
          if data.status is "okay"
            do window.location.reload
          else console.log "Not okay?"

      xhr.fail (data) ->
        if data.status is 403 
          alert """
            Sorry, but we are still in closed beta.

            Only invited people can log in. Feel free to browse 'though.
          """
          do navigator.id.logout

    onlogout    : ->
      $.post "/auth/logout",
        _csrf: csrf
        (data) ->
          console.log "Logout done!"
          $.removeCookie "email"
          do window.location.reload
  }

  $("[href='#!/authenticate']").click ->
    console.log "Authenticating..."
    do navigator.id.request

  $("[href='#!/logout']").click ->
    console.log "Logging off..."
    do navigator.id.logout