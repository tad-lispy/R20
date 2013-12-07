jQuery ($) ->
  $(".modal").each (i, modal) ->
    modal = $ modal
    modal.on "show.bs.modal", ->
      $(".modal").modal("hide")
      
    modal.on "shown.bs.modal", ->
      modal
        .find("form")
        .find("textarea, input[type='text']")
        .first()
        .focus()