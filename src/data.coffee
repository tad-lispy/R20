# Dummy data

module.exports =
  participants: [
    id        : "a1"
    name      : "Marcus Porcius Cato"
    role      : "Lawyer"
  ,
    id        : "a2"
    name      : "Marcus Tullius Cicero"
    role      : "Editor"
  ,
    id        : "a3"
    name      : "Gaius"
    role      : "Student"
  ,
    id        : "a4"
    name      : "Efigenia Grzyb"
    role      : "Reader"
  ]
  cases: [
    id        : "b1"
    author    : "a4"
    text      : "Była ąka i nima! Tera co?"
    questions : [
      "d1", "d2"
    ]
  ]
  questions: [
    id        : "d1"
    text      : "Jakie roszczenia przysługują właścicielowi zniszczonego pastwiska?"
    answers   : [
      author    : "a2"
      text      : "Restitutio ad integrum! To się rozumie samo przez się!"
      basis     : [
        act       : "c1"
        part      : "art. 361."
      ]
    ,
      author    : "a1"
      text      : "Nic się nie należy, bo volenti non fit iniuria. Było ąki pilnować, a nie teraz zawracać głowę mądrym prawniczym głową. Tak to nima!"
      basis     : [
      ]
    ]
  ]
  sources: [
    id        : "d1"
    name      : "Kodeks Cywilny"
    enacted   : "1964-04-23"
    type      : "Ustawa"
  ]
