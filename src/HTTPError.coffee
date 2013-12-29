module.exports = (code, message) ->
  error = new Error message or "HTTP Error"
  error.name = "HTTPError"
  error.code = code
  return error