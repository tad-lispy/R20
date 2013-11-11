$ ->
  csrf = $('body').data 'csrf'
  navigator.id.watch {
    loggedInUser: ($.cookie "email") or null
    onlogin     : (assertion) ->
      $.post "/auth/login",
        assertion : assertion
        _csrf: csrf
        (data) ->
          do window.location.reload

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