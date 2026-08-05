//
//  ProseLibrary.swift
//  BooksMyFriend
//
//  Chapter bodies for the bundled catalog.
//
//  Classics open with their genuine public-domain first lines; the remaining
//  body text is original prose written for this sample app, assembled
//  deterministically per chapter so pagination, highlights and resume points
//  are stable across launches.
//

import Foundation

/// A tiny deterministic PRNG so a given (book, chapter) always produces the
/// same text — important, because highlight ranges are persisted against it.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        // Avoid a zero state, which would lock splitmix64 at zero.
        state = UInt64(truncatingIfNeeded: seed) &* 0x9E37_79B9_7F4A_7C15 | 1
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum Mood {
    case literary, thriller, speculative, nonfiction, romance
}

enum ProseLibrary {

    // MARK: - Paragraph banks

    private static let literary = [
        "The house held its breath the way old houses do, settling one board at a time, as if it were remembering something it had promised not to say aloud. She stood in the hallway with her coat still buttoned and let the quiet arrange itself around her.",
        "Morning arrived without ceremony. Light crossed the floorboards, found the edge of the table, and stopped there, as though it had come a long way and intended to rest.",
        "There is a particular loneliness to knowing a place well. Every corner has already been assigned a memory, and there is no room left to be surprised by anything except yourself.",
        "He had learned, over the years, that most conversations are held twice — once out loud, badly, and once afterwards in the dark, perfectly, when it no longer matters what anyone says.",
        "The river ran the colour of weak tea and carried with it the whole indifferent business of the town: a bottle, a length of rope, a headline softening into pulp.",
        "She counted the things she had kept and the things she had let go, and found that the ledger did not balance in the direction she had expected. The kept things were heavier. The lost ones were louder.",
        "Nothing in the room had moved, and yet everything in it had aged, the way a photograph ages — not by changing, but by staying exactly the same while you do not.",
        "Outside, the wind worked at the shutters with the patience of something that has all night. Inside, the kettle began its slow argument with itself.",
        "They spoke about the weather because the weather was the only subject large enough to hold what neither of them was willing to name.",
        "It occurred to her then that courage is rarely the dramatic thing people imagine. Usually it is only the decision to stay in the room for one more minute.",
        "The town had two churches, one bridge, and a long municipal habit of forgiveness that stopped precisely at the edge of the water.",
        "Afterwards, he could recall the day only in fragments: the smell of cut grass, the sound of a screen door, the particular way she had said his name as if setting something down carefully.",
        "Grief, she discovered, does not arrive all at once. It is delivered in instalments, and there is no way to refuse the package.",
        "The lamp threw a circle of yellow onto the desk and left the rest of the room to fend for itself, which seemed, at that hour, an entirely reasonable arrangement.",
    ]

    private static let thriller = [
        "The phone rang at 3:14 in the morning, and by 3:16 she was dressed, because the only people who call at that hour are the ones who already know how the night ends.",
        "He checked the mirror twice. The grey sedan was still four cars back, keeping its distance with the discipline of someone paid to keep it.",
        "The file was thinner than it should have been. That was the first thing wrong with it. The second was that it had been signed by a man who had been dead for eleven months.",
        "Rain turned the loading dock into a sheet of moving light. Somewhere behind the containers, a door closed — not slammed, closed, which was worse.",
        "There were three ways out of the building and she had already decided that two of them were traps. That left the one nobody would expect her to survive.",
        "He counted the seconds between the flash and the sound and did not like the arithmetic.",
        "The address led to an office that had never held an office: bare desk, unplugged phone, a calendar still showing a month from four years ago.",
        "Everyone in the room was lying. The only useful question was which lies were load-bearing.",
        "She had two hours before the transfer cleared, and roughly nine minutes before anyone noticed she was gone.",
        "The security footage showed him entering at 8:02 and never leaving. The building had one door.",
        "Trust, in this line of work, was a currency you spent exactly once, and she had learned to check the change.",
        "The car was still warm. Whoever had left it had done so in a hurry, and had not bothered to take the envelope taped beneath the wheel arch.",
    ]

    private static let speculative = [
        "The station turned once every ninety seconds, and with each rotation the planet swung past the window like an argument nobody had won yet.",
        "They had solved hunger, distance, and — after a fashion — death. What remained was the older problem: what to do with an afternoon.",
        "The archive answered in a voice assembled from four hundred thousand recorded speakers, which meant it sounded like everyone and trusted no one.",
        "Light from the collapsed star reached them two centuries late, carrying news of an ending that had already stopped mattering to everybody involved.",
        "She placed her palm against the hull and felt, through nine centimetres of composite, the cold that had been waiting out there since before there were hands.",
        "The colony's first law was written in the plainest language available: nothing that thinks may be owned. The second law spent a hundred years defining thinks.",
        "Terraforming is a promise made to people who will not live to collect on it. That is what makes it the only honest work left.",
        "The signal repeated every eleven hours, forty-one minutes. It was not a message. It was a metronome, and something out there was keeping time.",
        "Memory, in the new architecture, was a shared municipal resource. You could visit your childhood, but so could anyone with clearance.",
        "The drive spun up with a sound like a held note, and the stars ahead compressed into a blue that had no name in any of the six surviving languages.",
        "He had been awake for three subjective days and eleven objective years, and the difference had begun to show in the way he spoke about home.",
        "Nobody had told the machines to grieve. They had simply been given enough context to work it out for themselves.",
    ]

    private static let nonfiction = [
        "Consider what actually happens in the first four seconds of a decision. Almost nothing you would call reasoning. What happens instead is retrieval — the mind reaching for the nearest previous case and asking whether this one rhymes.",
        "The most expensive assumptions are the ones that never get stated. They do not survive because they are true; they survive because nobody has ever been required to defend them out loud.",
        "There is a reliable pattern in the histories of failed organisations. Long before the collapse, the vocabulary narrows. People stop describing what they see and start repeating what is safe.",
        "Progress is usually mistaken for a line when it is closer to a ratchet: long stretches of apparent stillness, punctuated by a click that cannot be undone.",
        "A useful exercise: write down the three beliefs you hold that would be most costly to abandon. Those are not your convictions. Those are your infrastructure.",
        "Attention is the only genuinely scarce input. Everything else — capital, information, talent — has become abundant enough that the constraint moved elsewhere while we were still optimising the old one.",
        "The interval between cause and effect is where nearly all bad judgement lives. Shorten it and people learn quickly; stretch it and they will confidently learn the wrong lesson for decades.",
        "We tend to reward the visible save over the invisible prevention, which is a quiet but persistent tax on everyone doing the more valuable work.",
        "Habits are not built by motivation. They are built by reducing the number of decisions standing between you and the behaviour, until the behaviour is simply what happens next.",
        "When a measure becomes a target, it stops measuring. The failure is not the people gaming it — the failure is expecting a number to carry meaning it was never designed to hold.",
        "Expertise is largely the accumulation of well-organised failure. The expert is not the person who has been right most often; it is the person whose mistakes have been most specific.",
        "Complexity is rarely designed. It accumulates, one reasonable exception at a time, until nobody can describe the system without a diagram and an apology.",
    ]

    private static let romance = [
        "He was, she decided, the sort of person who apologised to furniture. This should not have been endearing, and it was deeply inconvenient that it was.",
        "They met the way most people meet now — badly, by accident, and in a queue — and spent the following year pretending that had not been the best morning of either of their lives.",
        "There was a version of the evening in which she said the true thing. She thought about it for the length of one song, and then the song ended, and so did the version.",
        "Love, in her experience, announced itself less like weather and more like a change of address: sudden paperwork, unfamiliar light, everything in slightly the wrong place.",
        "He laughed a half-beat late at everything, as though happiness had to travel a long way to reach him and he did not want to rush it.",
        "The letter stayed unsent in her coat pocket for eleven days, growing softer at the folds, becoming less a message and more a habit.",
        "They argued about the map for forty minutes and about nothing else for the rest of the trip, which is, she thought afterwards, roughly the correct ratio.",
        "It is a strange privilege to watch someone become themselves, and stranger still to suspect you are one of the reasons.",
        "She had built a life with excellent locks. He did not try any of them. He simply kept turning up, and eventually she opened the door herself.",
        "There is a specific silence that arrives when two people realise, at the same moment, that the conversation has changed shape.",
        "He remembered the coat, the rain, the terrible coffee. He could not, afterwards, remember a single word of what he had planned to say.",
        "Some people arrive in your life like a question. A few, very rarely, arrive like an answer you had stopped expecting.",
    ]

    private static func bank(for mood: Mood) -> [String] {
        switch mood {
        case .literary: literary
        case .thriller: thriller
        case .speculative: speculative
        case .nonfiction: nonfiction
        case .romance: romance
        }
    }

    // MARK: - Composition

    /// Builds a chapter body of roughly `paragraphs` paragraphs, deterministic
    /// for a given seed, optionally preceded by an authentic opening line.
    static func chapterBody(
        seed: Int,
        mood: Mood,
        paragraphs: Int,
        opening: String? = nil
    ) -> String {
        var generator = SeededGenerator(seed: seed)
        let primary = bank(for: mood)
        // A little cross-pollination keeps long books from feeling looped.
        let secondary = bank(for: mood == .nonfiction ? .literary : .nonfiction)

        var pieces: [String] = []
        if let opening { pieces.append(opening) }

        var pool = primary.shuffled(using: &generator)
        var spare = secondary.shuffled(using: &generator)

        while pieces.count < paragraphs {
            if pool.isEmpty { pool = primary.shuffled(using: &generator) }
            pieces.append(pool.removeLast())

            // Every fourth paragraph, borrow from the neighbouring register.
            if pieces.count % 4 == 0, pieces.count < paragraphs {
                if spare.isEmpty { spare = secondary.shuffled(using: &generator) }
                pieces.append(spare.removeLast())
            }
        }

        return pieces.joined(separator: "\n\n")
    }
}
