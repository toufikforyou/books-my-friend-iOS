//
//  Catalog.swift
//  BooksMyFriend
//
//  The bundled catalog. In a shipping app this would be the decoded response
//  of a store endpoint; it is deliberately shaped like one so `BookRepository`
//  can be swapped for a networked implementation without touching the UI.
//

import Foundation

enum Catalog {

    // MARK: - Books

    static let books: [Book] = [
        make(
            id: "b-lighthouse",
            title: "The Lighthouse at Vessel Bay",
            subtitle: "A novel",
            author: "Marguerite Hale",
            genre: .fiction,
            secondary: [.mystery],
            mood: .literary,
            year: 2024,
            publisher: "Northwind House",
            pages: 384,
            rating: 4.7,
            ratings: 24_180,
            readers: 148_000,
            price: 9.99,
            tags: ["Literary", "Family saga", "Coastal", "Slow burn"],
            synopsis: "Thirty years after her mother walked into the water and did not come back, Isla Reyner returns to the peninsula to sell a lighthouse she never wanted. What she finds in its logbooks is a second family, a second life, and a decade of entries written in her mother's hand after the year she supposedly died. A luminous novel about inheritance, tides, and the stories a place agrees to keep.",
            chapters: [
                "The Sale", "Logbook One", "Salt", "What the Keeper Wrote",
                "Low Water", "Vessel Bay, 1994", "The Second Family", "Fog Signal",
                "Everything the Sea Returns", "High Water",
            ],
            opening: "The lighthouse had been dark for eleven years, and still the town gave directions by it."
        ),
        make(
            id: "b-quietmachines",
            title: "Quiet Machines",
            subtitle: "How Attention Became the Only Currency",
            author: "Dr. Priya Raghunathan",
            genre: .business,
            secondary: [.science, .selfHelp],
            mood: .nonfiction,
            year: 2025,
            publisher: "Ledger & Co.",
            pages: 296,
            rating: 4.5,
            ratings: 11_902,
            readers: 92_400,
            price: 12.99,
            tags: ["Focus", "Technology", "Economics", "Productivity"],
            synopsis: "Every abundant resource creates a scarce one. Drawing on a decade of field research inside newsrooms, trading floors and hospital wards, Priya Raghunathan argues that the defining constraint of the century is not capital or compute but sustained human attention — and that most institutions are still optimising for the wrong bottleneck.",
            chapters: [
                "The Wrong Bottleneck", "Four Seconds", "The Interval Problem",
                "Measures That Stop Measuring", "The Cost of Interruption",
                "Designing for Depth", "What Comes After the Feed",
            ]
        ),
        make(
            id: "b-nightferry",
            title: "The Night Ferry",
            subtitle: nil,
            author: "Adem Koray",
            genre: .mystery,
            secondary: [.adventure],
            mood: .thriller,
            year: 2023,
            publisher: "Blackwater Press",
            pages: 352,
            rating: 4.6,
            ratings: 33_450,
            readers: 210_300,
            price: 8.99,
            tags: ["Thriller", "Istanbul", "Twisty", "Page-turner"],
            synopsis: "A financial investigator boards the last ferry across the Bosphorus with a briefcase she was told not to open. Forty minutes later the ferry docks, the briefcase is gone, and so is the man who gave it to her. A relentless, clockwork thriller that unfolds across a single sleepless night.",
            chapters: [
                "22:40", "The Briefcase", "Kadıköy", "Six Minutes of Water",
                "The Man in Seat 14", "Wire Transfer", "The Second Ferry",
                "05:15", "Daylight",
            ],
            opening: "The phone rang at 3:14 in the morning, and by 3:16 she was dressed."
        ),
        make(
            id: "b-orbitals",
            title: "Orbitals",
            subtitle: "Book One of the Long Rotation",
            author: "Yara Emeka-Stone",
            genre: .sciFi,
            secondary: [.adventure, .fiction],
            mood: .speculative,
            year: 2025,
            publisher: "Vector Books",
            pages: 448,
            rating: 4.8,
            ratings: 41_220,
            readers: 264_900,
            price: nil,
            tags: ["Space opera", "First contact", "Series", "Award winner"],
            synopsis: "Station Kestrel has completed forty million rotations and has never once received a message. On the forty-million-and-first, it receives eleven. The first volume of the Long Rotation: a patient, humane space opera about what a civilisation owes to the things it builds.",
            chapters: [
                "Forty Million Rotations", "Eleven Messages", "The Archive Speaks",
                "Clearance", "Cold Sleep, Warm Debt", "The Metronome",
                "Nothing That Thinks", "Blue With No Name", "Long Rotation",
            ],
            opening: "The station turned once every ninety seconds, and had done so without complaint since before anyone aboard was born."
        ),
        make(
            id: "b-saltandhoney",
            title: "Salt and Honey",
            subtitle: nil,
            author: "Cleo Ferrante",
            genre: .romance,
            secondary: [.fiction],
            mood: .romance,
            year: 2024,
            publisher: "Marigold",
            pages: 328,
            rating: 4.4,
            ratings: 52_800,
            readers: 318_000,
            price: 7.99,
            tags: ["Slow burn", "Second chance", "Sicily", "Food"],
            synopsis: "Nine years after she left him at a bus stop in Palermo without an explanation, Marina returns to run her grandmother's bakery — three doors down from the restaurant he never left. A warm, sharp-tongued romance about the recipes we inherit and the apologies we owe.",
            chapters: [
                "Three Doors Down", "The Bus Stop, Nine Years Ago", "Semolina",
                "The Feast of Santa Rosalia", "What Nonna Wrote", "Bitter Orange",
                "The Long Table", "Salt and Honey",
            ]
        ),
        make(
            id: "b-hollowcrown",
            title: "The Hollow Crown of Aventhal",
            subtitle: "The Ash Cycle, Volume I",
            author: "Rowan Fitzgerald",
            genre: .fantasy,
            secondary: [.adventure],
            mood: .speculative,
            year: 2022,
            publisher: "Emberline",
            pages: 612,
            rating: 4.6,
            ratings: 67_400,
            readers: 402_100,
            price: 10.99,
            tags: ["Epic fantasy", "Magic system", "Series", "Doorstopper"],
            synopsis: "The crown of Aventhal has no head to sit on and no metal in it. It is a debt, and it has come due. First volume of the Ash Cycle.",
            chapters: [
                "A Debt in the Shape of a Crown", "Ashfall", "The Cartographer's Daughter",
                "Nine Names for Fire", "The Hollow Court", "What the Ash Remembers",
                "Siege", "The Reckoning of Aventhal",
            ]
        ),
        make(
            id: "b-deepwater",
            title: "Deepwater Protocol",
            subtitle: nil,
            author: "Sana Qureshi",
            genre: .mystery,
            secondary: [.sciFi],
            mood: .thriller,
            year: 2025,
            publisher: "Blackwater Press",
            pages: 368,
            rating: 4.3,
            ratings: 9_140,
            readers: 61_500,
            price: nil,
            tags: ["Techno-thriller", "Submarine", "Debut"],
            synopsis: "Eleven hundred metres down, a research submersible receives a maintenance instruction from a company that dissolved four years ago. Compliance is automatic. Surfacing is not.",
            chapters: [
                "1,100 Metres", "The Instruction", "Ballast", "Company of Ghosts",
                "Pressure Hull", "Ascent Denied", "Surface",
            ]
        ),
        make(
            id: "b-marble",
            title: "The Marble and the Mason",
            subtitle: "A History of Unfinished Things",
            author: "Tobias Lindqvist",
            genre: .history,
            secondary: [.philosophy],
            mood: .nonfiction,
            year: 2023,
            publisher: "Aldgate University Press",
            pages: 424,
            rating: 4.5,
            ratings: 6_720,
            readers: 38_900,
            price: 14.99,
            tags: ["Architecture", "Essays", "Europe", "Award winner"],
            synopsis: "Cathedrals that took four centuries. Canals abandoned at the halfway mark. A sweeping history of projects designed by people who knew they would never see them finished — and what that habit of mind cost us when we lost it.",
            chapters: [
                "Four Hundred Years", "The Halfway Canal", "Masons Without Names",
                "The Ratchet", "Debt to the Unborn", "Everything We Stopped Building",
            ]
        ),
        make(
            id: "b-stillness",
            title: "The Practice of Stillness",
            subtitle: "Twelve Weeks to a Quieter Mind",
            author: "Nadia Bakr",
            genre: .selfHelp,
            secondary: [.philosophy],
            mood: .nonfiction,
            year: 2024,
            publisher: "Willow Path",
            pages: 248,
            rating: 4.2,
            ratings: 18_330,
            readers: 176_000,
            price: nil,
            tags: ["Mindfulness", "Habits", "Anxiety", "Workbook"],
            synopsis: "A twelve-week programme built on one unfashionable premise: you cannot think your way out of a restless mind, but you can shorten the distance between you and the practice until stillness is simply what happens next.",
            chapters: [
                "Week One: Arriving", "Week Two: The Distance", "Week Three: Breath as Anchor",
                "Week Four: The Restless Hour", "Week Six: Sitting With Discomfort",
                "Week Nine: Off the Cushion", "Week Twelve: What Remains",
            ]
        ),
        make(
            id: "b-carbon",
            title: "Carbon & Consequence",
            subtitle: "The Next Hundred Winters",
            author: "Elias Thornbury",
            genre: .science,
            secondary: [.history],
            mood: .nonfiction,
            year: 2025,
            publisher: "Meridian",
            pages: 356,
            rating: 4.7,
            ratings: 14_600,
            readers: 88_200,
            price: 13.99,
            tags: ["Climate", "Data", "Policy", "Hopeful"],
            synopsis: "Neither doom nor denial. A clear-eyed account of what the next century of climate actually looks like from inside the engineering, and why the most important decisions are being made by people you have never heard of.",
            chapters: [
                "The Next Hundred Winters", "What the Ice Recorded", "The Grid Problem",
                "Concrete, Steel, Ammonia", "The Adaptation Century",
                "Who Actually Decides", "Reasons for Work",
            ]
        ),
        make(
            id: "b-glasshour",
            title: "The Glass Hour",
            subtitle: nil,
            author: "Marguerite Hale",
            genre: .fiction,
            secondary: [.romance],
            mood: .literary,
            year: 2021,
            publisher: "Northwind House",
            pages: 302,
            rating: 4.4,
            ratings: 19_450,
            readers: 121_000,
            price: 8.49,
            tags: ["Literary", "Grief", "Sisters"],
            synopsis: "Two sisters, one house, and the sixty minutes each evening when the light comes through the west windows and neither of them can pretend the other isn't there.",
            chapters: [
                "West Windows", "The Inventory", "What Mother Kept",
                "Sixty Minutes", "The Glass Hour", "After the Light",
            ]
        ),
        make(
            id: "b-signalfire",
            title: "Signalfire",
            subtitle: "The Long Rotation, Book Two",
            author: "Yara Emeka-Stone",
            genre: .sciFi,
            secondary: [.fiction],
            mood: .speculative,
            year: 2026,
            publisher: "Vector Books",
            pages: 470,
            rating: 4.9,
            ratings: 8_930,
            readers: 47_600,
            price: 14.99,
            tags: ["Space opera", "Sequel", "New release"],
            synopsis: "The eleven messages have been answered. Now Station Kestrel must decide what to do with a reply it does not have the vocabulary to refuse. The second volume of the Long Rotation.",
            chapters: [
                "The Reply", "Six Surviving Languages", "Municipal Memory",
                "The Colony's First Law", "Signalfire", "Two Centuries Late", "Keeping Time",
            ]
        ),
        make(
            id: "b-cartographers",
            title: "The Cartographer's Apprentice",
            subtitle: nil,
            author: "Rowan Fitzgerald",
            genre: .adventure,
            secondary: [.fantasy],
            mood: .speculative,
            year: 2020,
            publisher: "Emberline",
            pages: 388,
            rating: 4.3,
            ratings: 27_800,
            readers: 165_400,
            price: nil,
            tags: ["Adventure", "Maps", "Coming of age"],
            synopsis: "In a guild where maps are legally binding, redrawing a coastline is an act of war. A young apprentice discovers her master has been quietly moving a border for thirty years.",
            chapters: [
                "The Guild of True Lines", "An Inch of Coastline", "Ink and Treason",
                "The Moving Border", "Survey", "What the Map Made True",
            ]
        ),
        make(
            id: "b-lastharvest",
            title: "The Last Harvest of Vinca Hollow",
            subtitle: nil,
            author: "Adem Koray",
            genre: .horror,
            secondary: [.mystery],
            mood: .thriller,
            year: 2024,
            publisher: "Blackwater Press",
            pages: 310,
            rating: 4.1,
            ratings: 12_070,
            readers: 74_800,
            price: 7.49,
            tags: ["Folk horror", "Rural", "Atmospheric"],
            synopsis: "The valley has brought in a perfect harvest for eighty-one consecutive years. The agricultural inspector sent to explain it does not intend to stay for the eighty-second.",
            chapters: [
                "Eighty-One Years", "The Inspector", "Rotation", "The Long Field",
                "What Is Owed the Soil", "Harvest",
            ]
        ),
        make(
            id: "b-firstprinciple",
            title: "First Principle",
            subtitle: "Rebuilding How You Decide",
            author: "Dr. Priya Raghunathan",
            genre: .business,
            secondary: [.selfHelp],
            mood: .nonfiction,
            year: 2021,
            publisher: "Ledger & Co.",
            pages: 272,
            rating: 4.4,
            ratings: 22_150,
            readers: 198_700,
            price: 11.99,
            tags: ["Decision making", "Strategy", "Bestseller"],
            synopsis: "The companion to Quiet Machines. A practical method for finding the unstated assumptions holding up your decisions — and a field guide to dismantling them before they dismantle you.",
            chapters: [
                "Unstated Assumptions", "Load-Bearing Beliefs", "The Nearest Previous Case",
                "Specific Failure", "One Reasonable Exception at a Time", "Rebuilding",
            ]
        ),
        make(
            id: "b-nineteendoors",
            title: "Nineteen Doors",
            subtitle: nil,
            author: "Ines Vidal",
            genre: .mystery,
            secondary: [.fiction],
            mood: .thriller,
            year: 2023,
            publisher: "Corvid",
            pages: 344,
            rating: 4.5,
            ratings: 31_900,
            readers: 188_400,
            price: 8.99,
            tags: ["Locked room", "Detective", "Series"],
            synopsis: "A hotel with nineteen doors and eighteen guests. Detective Aurelio Sanz has until checkout to work out which door was never opened, and why the corridor camera shows it opening anyway.",
            chapters: [
                "Eighteen Guests", "The Nineteenth Door", "Checkout",
                "Corridor Camera", "The Guest Who Wasn't", "Room Nineteen",
            ]
        ),
        make(
            id: "b-quietfields",
            title: "Quiet Fields",
            subtitle: "Poems",
            author: "Owen Marrow",
            genre: .poetry,
            secondary: [.fiction],
            mood: .literary,
            year: 2022,
            publisher: "Small Hours",
            pages: 118,
            rating: 4.6,
            ratings: 4_210,
            readers: 21_300,
            price: nil,
            tags: ["Poetry", "Nature", "Short"],
            synopsis: "Forty-one poems on weather, work, and the particular loneliness of knowing a place well.",
            chapters: ["Field Notes", "Weather", "Work", "Quiet Fields"]
        ),
        make(
            id: "b-ironbridge",
            title: "The Woman Who Built the Iron Bridge",
            subtitle: "A Life of Hannah Ashcroft",
            author: "Tobias Lindqvist",
            genre: .biography,
            secondary: [.history],
            mood: .nonfiction,
            year: 2025,
            publisher: "Aldgate University Press",
            pages: 466,
            rating: 4.8,
            ratings: 7_640,
            readers: 44_100,
            price: 15.99,
            tags: ["Biography", "Engineering", "Victorian", "New release"],
            synopsis: "She signed forty years of drawings with her husband's name. The definitive biography of the engineer behind eleven of Britain's surviving bridges.",
            chapters: [
                "Someone Else's Signature", "The Apprenticeship", "Eleven Bridges",
                "The Institution", "Attribution", "What the Drawings Show", "Legacy",
            ]
        ),
        make(
            id: "b-stoicroom",
            title: "The Room and the Stoic",
            subtitle: "Ancient Discipline for a Distracted Age",
            author: "Nadia Bakr",
            genre: .philosophy,
            secondary: [.selfHelp, .history],
            mood: .nonfiction,
            year: 2022,
            publisher: "Willow Path",
            pages: 264,
            rating: 4.3,
            ratings: 16_880,
            readers: 142_600,
            price: 9.49,
            tags: ["Stoicism", "Philosophy", "Practical"],
            synopsis: "What the Stoics actually said, stripped of the productivity gloss — and why the hardest of their practices is also the least quotable.",
            chapters: [
                "Not a Life Hack", "The Dichotomy, Properly Stated", "On Anger",
                "The Unquotable Practice", "Death, Plainly", "One More Minute in the Room",
            ]
        ),
        make(
            id: "b-tidewater",
            title: "Tidewater Girls",
            subtitle: nil,
            author: "Cleo Ferrante",
            genre: .fiction,
            secondary: [.romance],
            mood: .literary,
            year: 2020,
            publisher: "Marigold",
            pages: 358,
            rating: 4.2,
            ratings: 25_600,
            readers: 154_900,
            price: 7.99,
            tags: ["Friendship", "Summer", "Coastal"],
            synopsis: "Four friends, one rented house, and the last summer before everything they had assumed would keep quietly stopped keeping.",
            chapters: [
                "The Rented House", "June", "The Ledger", "August",
                "What We Assumed Would Keep", "September",
            ]
        ),
        make(
            id: "b-atlasofsmall",
            title: "An Atlas of Small Countries",
            subtitle: "Travels in the Overlooked",
            author: "Ines Vidal",
            genre: .adventure,
            secondary: [.history, .biography],
            mood: .nonfiction,
            year: 2024,
            publisher: "Corvid",
            pages: 332,
            rating: 4.5,
            ratings: 9_880,
            readers: 66_200,
            price: nil,
            tags: ["Travel", "Essays", "Geography"],
            synopsis: "Eleven nations you could cross on foot in a day, and the outsized histories they carry. Travel writing with the patience of a good local guide.",
            chapters: [
                "A Day on Foot", "Borders Drawn in Pencil", "The Smallest Parliament",
                "Currency and Pride", "Eleven Anthems", "Leaving",
            ]
        ),
        make(
            id: "b-terminalvelocity",
            title: "Terminal Velocity",
            subtitle: nil,
            author: "Sana Qureshi",
            genre: .sciFi,
            secondary: [.mystery],
            mood: .speculative,
            year: 2026,
            publisher: "Vector Books",
            pages: 398,
            rating: 4.6,
            ratings: 3_410,
            readers: 19_800,
            price: 13.49,
            tags: ["Near future", "New release", "Corporate"],
            synopsis: "A courier with a neural implant she cannot legally read discovers she has been carrying the same eleven seconds of memory across four continents for a year.",
            chapters: [
                "Eleven Seconds", "Courier", "Read Access Denied", "Four Continents",
                "The Client", "Terminal Velocity",
            ]
        ),
        make(
            id: "b-emberwood",
            title: "Emberwood",
            subtitle: "The Ash Cycle, Volume II",
            author: "Rowan Fitzgerald",
            genre: .fantasy,
            secondary: [.adventure],
            mood: .speculative,
            year: 2024,
            publisher: "Emberline",
            pages: 648,
            rating: 4.7,
            ratings: 38_900,
            readers: 231_500,
            price: 11.99,
            tags: ["Epic fantasy", "Sequel", "Series"],
            synopsis: "The crown has found a head. The forest has opinions about it. Volume two of the Ash Cycle.",
            chapters: [
                "A Head for the Crown", "The Forest's Objection", "Nine Names, Spoken",
                "Emberwood", "The Cartographer Returns", "Ashfall, Again", "The Second Reckoning",
            ]
        ),
        make(
            id: "b-morningpages",
            title: "Morning Pages",
            subtitle: "A Year of Beginning Again",
            author: "Owen Marrow",
            genre: .selfHelp,
            secondary: [.poetry, .biography],
            mood: .literary,
            year: 2025,
            publisher: "Small Hours",
            pages: 208,
            rating: 4.4,
            ratings: 5_940,
            readers: 51_700,
            price: nil,
            tags: ["Creativity", "Journal", "Daily"],
            synopsis: "Three hundred and sixty-five short entries on starting over, written across the year the author stopped publishing and began writing again.",
            chapters: ["January", "Spring", "The Middle Months", "Autumn", "Beginning Again"]
        ),
    ]

    // MARK: - Lookup

    static let byID: [String: Book] = Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0) })

    static func book(id: String) -> Book? { byID[id] }

    static var authors: [String] {
        Array(Set(books.map(\.author))).sorted()
    }

    // MARK: - Curated shelves

    static let shelves: [Shelf] = [
        Shelf(
            id: "s-spotlight",
            title: "Editor's Spotlight",
            subtitle: "Hand-picked this week",
            style: .hero,
            bookIDs: ["b-lighthouse", "b-orbitals", "b-nightferry", "b-carbon"]
        ),
        Shelf(
            id: "s-trending",
            title: "Trending Now",
            subtitle: "What everyone is reading",
            style: .ranked,
            bookIDs: ["b-hollowcrown", "b-saltandhoney", "b-nightferry", "b-quietmachines",
                      "b-emberwood", "b-nineteendoors", "b-firstprinciple", "b-orbitals"]
        ),
        Shelf(
            id: "s-new",
            title: "New This Season",
            subtitle: "Fresh off the press",
            style: .standard,
            bookIDs: ["b-signalfire", "b-ironbridge", "b-terminalvelocity", "b-carbon",
                      "b-morningpages", "b-quietmachines"]
        ),
        Shelf(
            id: "s-free",
            title: "Free to Read",
            subtitle: "No subscription needed",
            style: .standard,
            bookIDs: ["b-orbitals", "b-deepwater", "b-stillness", "b-cartographers",
                      "b-quietfields", "b-atlasofsmall", "b-morningpages"]
        ),
        Shelf(
            id: "s-short",
            title: "Finish in a Weekend",
            subtitle: "Under 300 pages",
            style: .compact,
            bookIDs: ["b-quietfields", "b-morningpages", "b-stillness", "b-firstprinciple",
                      "b-stoicroom", "b-glasshour"]
        ),
        Shelf(
            id: "s-mind",
            title: "For a Quieter Mind",
            subtitle: "Philosophy, focus and practice",
            style: .standard,
            bookIDs: ["b-stillness", "b-stoicroom", "b-quietmachines", "b-morningpages", "b-marble"]
        ),
        Shelf(
            id: "s-worlds",
            title: "Worlds Worth Getting Lost In",
            subtitle: "Epic fantasy and space opera",
            style: .standard,
            bookIDs: ["b-hollowcrown", "b-emberwood", "b-orbitals", "b-signalfire",
                      "b-cartographers", "b-terminalvelocity"]
        ),
        Shelf(
            id: "s-latenight",
            title: "Late Night Reads",
            subtitle: "Keep the light on",
            style: .compact,
            bookIDs: ["b-lastharvest", "b-nineteendoors", "b-nightferry", "b-deepwater",
                      "b-terminalvelocity", "b-glasshour"]
        ),
    ]

    /// A rotating pull-quote for the Discover header.
    static let quotes: [(text: String, source: String)] = [
        ("A reader lives a thousand lives before he dies. The man who never reads lives only one.", "George R.R. Martin"),
        ("Books are a uniquely portable magic.", "Stephen King"),
        ("I have always imagined that Paradise will be a kind of library.", "Jorge Luis Borges"),
        ("Reading is a conversation. All books talk. But a good book listens as well.", "Mark Haddon"),
        ("There is no friend as loyal as a book.", "Ernest Hemingway"),
    ]

    // MARK: - Construction

    private static func make(
        id: String,
        title: String,
        subtitle: String?,
        author: String,
        genre: Genre,
        secondary: [Genre],
        mood: Mood,
        year: Int,
        publisher: String,
        pages: Int,
        rating: Double,
        ratings: Int,
        readers: Int,
        price: Decimal?,
        tags: [String],
        synopsis: String,
        chapters chapterTitles: [String],
        opening: String? = nil
    ) -> Book {
        let seed = abs(id.hashValue % 100_000)

        let chapters = chapterTitles.enumerated().map { index, chapterTitle in
            // Longer books get denser chapters; the first chapter carries the
            // authentic opening line where we have one.
            let paragraphCount = 9 + (pages / 90) + (index % 3)
            return Chapter(
                id: "\(id)-c\(index)",
                number: index + 1,
                title: chapterTitle,
                body: ProseLibrary.chapterBody(
                    seed: seed &+ index &* 7919,
                    mood: mood,
                    paragraphs: paragraphCount,
                    opening: index == 0 ? opening : nil
                )
            )
        }

        return Book(
            id: id,
            title: title,
            subtitle: subtitle,
            author: author,
            narrator: nil,
            genre: genre,
            secondaryGenres: secondary,
            synopsis: synopsis,
            publishedYear: year,
            publisher: publisher,
            language: "English",
            pageCount: pages,
            rating: rating,
            ratingCount: ratings,
            readerCount: readers,
            price: price,
            isPremium: price != nil,
            tags: tags,
            chapters: chapters,
            reviews: ReviewFactory.reviews(bookID: id, rating: rating, count: 5),
            coverSeed: seed
        )
    }
}

// MARK: - Reviews

private enum ReviewFactory {
    private static let names = [
        "Amara O.", "Jonas P.", "Mei-Lin C.", "Rafael S.", "Freya N.", "Dev K.",
        "Sofia B.", "Tomás R.", "Aisha M.", "Henrik L.", "Nour A.", "Kai W.",
    ]

    private static let positives: [(String, String)] = [
        ("Could not put it down",
         "I read this in two sittings and immediately started again. The pacing is superb and the ending earns every page that came before it."),
        ("Genuinely stayed with me",
         "Three weeks later I'm still thinking about the middle section. It does the rare thing of being both clever and kind."),
        ("Beautifully written",
         "Every other paragraph had me reaching for the highlight tool. The prose never shows off, it just quietly lands."),
        ("Worth the hype",
         "I was sceptical given how much I'd seen about this one, but it deserves the attention. Recommended it to four people already."),
        ("Perfect for a long flight",
         "Absorbing from the first page. I looked up and we were descending."),
    ]

    private static let mixed: [(String, String)] = [
        ("Strong start, uneven middle",
         "The opening third is excellent. It sags a little around the halfway mark before recovering for a very good final act."),
        ("Good, not great",
         "Well made and clearly researched, but it never quite surprised me. Still glad I read it."),
        ("A slow burn — be patient",
         "It takes about eighty pages to find its footing. Once it does, it's excellent, but I nearly gave up early."),
    ]

    static func reviews(bookID: String, rating: Double, count: Int) -> [Review] {
        var generator = SeededGenerator(seed: abs(bookID.hashValue))
        var results: [Review] = []
        let shuffledNames = names.shuffled(using: &generator)

        for index in 0..<count {
            // Mix in a mixed-tone review roughly in line with the average rating.
            let useMixed = index == count - 2 && rating < 4.6
            let source = useMixed
                ? mixed[Int.random(in: 0..<mixed.count, using: &generator)]
                : positives[index % positives.count]

            results.append(
                Review(
                    id: "\(bookID)-r\(index)",
                    author: shuffledNames[index % shuffledNames.count],
                    avatarSeed: Int.random(in: 0..<360, using: &generator),
                    rating: useMixed ? 3 : (rating >= 4.6 ? 5 : Int.random(in: 4...5, using: &generator)),
                    date: .now.addingTimeInterval(-Double.random(in: 86_400...86_400 * 200, using: &generator)),
                    title: source.0,
                    body: source.1,
                    helpfulCount: Int.random(in: 3...240, using: &generator)
                )
            )
        }
        return results
    }
}
