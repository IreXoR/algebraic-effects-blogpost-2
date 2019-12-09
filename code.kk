module b

// Eine Person ist string, der dessen Name repräsentiert
alias person = string

// Ein Teilnehmer ist eines der folgenden:
// - ein Single, das eine Person repräsentiert.
// - ein Paar, dass zwei Personen repräsentiert, die sich gegenseitig nicht beschänken dürfen.
type participant {
    Single(p : person)
    Pair(p1 : person, p2 : person)
}

// Eine Zuordnung besteht aus einer Person, die die zweite Person beschenkt.
alias matching = (person, person)

fun is-pair(matching : matching, participants : list<participant>) : <exn, div> bool {
    val (z1, z2) = matching
    match(participants){
      Cons(Pair(p1, p2), xs) -> {
        val matching-is-pair = z1 == p1 && z2 == p2 || z1 == p2 && z2 == p1
        matching-is-pair || is-pair(matching, xs)
      }
      Cons(Single(__), xs) -> is-pair(matching, xs)
      Nil -> False
    } 
}

fun is-self-giving(matching : matching) {
  val (z1, z2) = matching
  z1 == z2
}

fun is-valid-matching(matching : matching, participants : list<participant>) {
  !is-self-giving(matching) && !is-pair(matching, participants)
}

effect random {
    fun random-pair(a : list<person>, b : list<person>) : (person, person)
}

// Hilfsfunktion um alle Personen aus einer Liste von Teilnehmer zu extrahieren
fun flatten-participants(participants: list<participant>)  {
    participants.flatmap(fun(p){
      match(p){
        Pair(a, b) -> [a, b]
        Single(a) -> [a]
      }})}


// Hilfsfunktion um ein Element aus einer Liste zu entfernen
fun remove-person(l: list<person>, element : person) : list<person> {
  l.remove(fun(x){x == element}) 
}

// Implementierung der Wichtel-Funktion
fun find-matching-helper(not-yet-giving: list<person>, 
                         not-yet-receiving: list<person>, 
                         participants: list<participant>,
                         matchings: list<matching>) : <div, random, exn> maybe<list<matching>> {
  match( not-yet-giving ) {
    Cons(_,_) -> {
      val matching = random-pair(not-yet-giving, not-yet-receiving)
      if(is-valid-matching(matching, participants)) then {
         val (giver, receiver) = matching
         find-matching-helper(
            remove-person(not-yet-giving, giver),
            remove-person(not-yet-receiving, receiver),
            participants,
            Cons(matching, matchings)
         )
      } else {
        Nothing 
      }}
    Nil -> Just(matchings)
  }
}


fun find-matching(participants : list<participant>) : <div, random, exn> maybe<list<matching>>{
  val persons = flatten-participants(participants) 
  find-matching-helper(persons, persons, participants, [])
}



fun random-element(x : list<a>) : <ndet, exn> a {
  val r-idx = random-int() % x.length
  match(x[r-idx]){
    Just(a) -> a
    Nothing -> throw("List is empty")
  }
}

val random-pair-handler = handler {
  return x -> x 
  random-pair(a, b) -> resume((random-element(a), random-element(b)))
}


fun print-matchings(matchings : list<matching>) {
    match(matchings){
       Cons(x, xs) -> {
           val (a, b) = x
           println(a + " " + b)
           print-matchings(xs)
       }
       Nil -> println("")
   }
}


// public fun main()  {
// 
//  val participants = [Pair("Aaron", "Jaqueline"), Pair("Denise", "Blake"),
//                      Single("Timothy"), Single("O'Shaughnessy")]
//
//  val r = random-pair-handler({find-matching(participants)})
//
//  r.map(fun(x){
//    print-matchings(x)
//    println("")
//  })
//}

val random-pair-handler-on-steroids = handler {
  return x -> [x]
  random-pair(a, b) -> {
    val x = random-element(a)
    b.foldl([], fun(acc, y){acc + resume((x, y))})
  }
}

public fun main()  {
 
  val participants = [Pair("Aaron", "Jaqueline"), Pair("Denise", "Blake"),
                      Pair("Aarona", "Jaquelinea"), Pair("Denisea", "Blakea"),
                      Pair("Aaronb", "Jaquelineb"), Pair("Deniseb", "Blakeb"),
                      Pair("Aaronc", "Jaquelinec"), Pair("Denisec", "Blakec"),
                      Single("Timothy"), Single("O'Shaughnessy")]

  val r = random-pair-handler-on-steroids({find-matching(participants)})

  val x = r.map(fun(x){
    x.map(print-matchings)
  })

  1
}

