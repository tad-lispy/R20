$ ->
  $('[data-search]').each ->
    element     = $ @
    collection  = element.data "search"
    url         = "/#{collection}"

    # Make sure  submit is enabled
    element.find("[type='submit']").prop "disabled", false

    if (element.data "target") and (element.data "source")
      source = $ element.data "source"
      target = $ element.data "target"
      search = element.find "input[name='text']"

      element.submit (event) ->
        do event.preventDefault
        do target.empty
        $.get url, text: search.val(), (data) ->
          for doc in data
            item = do source.clone
            for key, value of doc
              item.find("[name='#{key}']").val value
              item.find("[data-fill='#{key}']").html value

            target.append item.removeClass "hide"

      do element.submit