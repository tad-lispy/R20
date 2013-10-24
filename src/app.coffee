do (require "source-map-support").install

express   = require "express"
path      = require "path"
_         = require "underscore"
mongoose  = require "mongoose"

app = do express

app.set "name",     "Radzimy.co"
app.set "motto",    "Podnosimy świadomość prawną."
app.set "engine",   "R20"
app.set "version",  (require "../package.json").version
app.set "repo",     (require "../package.json").repo

author = (require "../package.json").author.match ///
  ^
  \s*
  ([^<\(]+)     # name
  \s+
  (?:<(.*)>)?   # e-mail
  \s*
  (?:\((.*)\))? # website
  \s*
///
app.set "author",
  name    : do author[1]?.trim
  email   : do author[2]?.trim
  website : do author[3]?.trim

app.use (req, res, next) ->
  res.locals.settings = _(app.settings).pick [
    "name"
    "motto"
    "engine"
    "version"
    "repo"
    "env"
    "author"
  ]

  res.locals.url = req.url

  do next

app.use express.bodyParser {}

controllers = {}
for controller in [
  "home"
  "search"
  "about"
  "story"
]
  controllers[controller] = require "./controllers/#{controller}"


app.get "/",          controllers.home.get
app.get "/main",      controllers.home.main

app.post "/search",   controllers.search.post

app.get "/story/new", controllers.story.post
app.get "/story/:id", controllers.story.get


app.get "/about", controllers.about.get

# Get some dummy data
dummy = require "./data"



app.use '/js', express.static 'assets/scripts/app'
app.use '/js', express.static 'assets/scripts/vendor'


app.get "/stories", (req, res) ->
  res.json stories: dummy.stories.map (story) -> story.id

app.get "/stories/:id", (req, res) ->
  stories = dummy.stories.filter (story) -> story.id is req.params.id
  story = stories[0]
  if not story then return res.json error: "No such story"

  res.json story

app.get "/stories/:id/questions", (req, res) ->
  stories = dummy.stories.filter (story) -> story.id is req.params.id
  story = stories[0]
  if not story then return res.json error: "No such story"

  questions = story.questions.map (question) ->
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

app.get "/questions/:id/stories", (req, res) ->
  stories = dummy.stories.filter (story) ->
    questions = story.questions.filter (question) -> question is req.params.id
    return questions.length

  res.json { stories }

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

mongoose.connect "mongodb://localhost/R20"
app.listen "3210"