do (require "source-map-support").install

express = require "express"
path    = require "path"
_       = require "underscore"
app = do express

app.set "name",     "Radzimy.co"
app.set "motto",    "Podnosimy świadomość prawną."
app.set "engine",   "R20"
app.set "version",  (require "../package.json").version
app.set "repo",     (require "../package.json").repo

app.use (req, res, next) ->
  res.locals.settings = _(app.settings).pick [
    "name"
    "motto"
    "engine"
    "version"
    "repo"
    "env"
  ]

  res.locals.url = req.url

  do next

app.use express.bodyParser {}

controllers =
  home    : require "./controllers/home"
  search  : require "./controllers/search"
  about   : require "./controllers/about"

app.get "/", controllers.home.get

app.post "/search", controllers.search.post

app.get "/main", controllers.home.main
# Get some dummy data
dummy = require "./data"

app.get "/about", controllers.about.get

app.use '/js', express.static 'assets/scripts/app'
app.use '/js', express.static 'assets/scripts/vendor'


app.get "/cases", (req, res) ->
  res.json cases: dummy.cases.map (casus) -> casus.id

app.get "/cases/:id", (req, res) ->
  cases = dummy.cases.filter (casus) -> casus.id is req.params.id
  casus = cases[0]
  if not casus then return res.json error: "No such case"

  res.json casus

app.get "/cases/:id/questions", (req, res) ->
  cases = dummy.cases.filter (casus) -> casus.id is req.params.id
  casus = cases[0]
  if not casus then return res.json error: "No such case"

  questions = casus.questions.map (question) ->
    questions    = dummy.questions.filter (q) -> q.id is question
    question = questions[0]
    if not question then return error: "no such question"
    return id: question.id, text: question.text

  res.json { questions }


app.get "/questions", (req, res) ->
  res.json questions: dummy.questions.map (question) -> question.id

app.get "/questions/:id", (req, res) ->
  questions = dummy.questions.filter (question) -> question.id is req.params.id
  res.json questions[0] or error: "No such question"

app.get "/questions/:id/cases", (req, res) ->
  cases = dummy.cases.filter (casus) ->
    questions = casus.questions.filter (question) -> question is req.params.id
    return questions.length

  res.json { cases }

app.get "/participants", (req, res) ->
  res.json participants: dummy.participants.map (participant) -> participant.id

app.get "/participants/:id", (req, res) ->
  participants = dummy.participants.filter (participant) -> participant.id is req.params.id
  res.json participants[0] or error: "no such participant"

app.get "/participants/:id/questions", (req, res) ->
  questions = dummy.questions.filter (question) ->
    answers = question.answers.filter (answer) -> answer.author is req.params.id
    return answers.length
  questions = questions.map (question) -> id: question.id, text: question.text

  res.json { questions }

app.get "/sources", (req, res) ->
  res.json dummy.sources

app.listen "3210"