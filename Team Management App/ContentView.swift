import SwiftUI

struct TeamMember: Identifiable, Codable {
    var id = UUID()
    var name: String
    var position: String
    var jerseyNumber: String
    var attendance: [Date] = []
}

struct Game: Identifiable, Codable {
    var id = UUID()
    var opponent: String
    var date: Date
    var location: String
    var result: String
    var notes: String
}

struct ContentView: View {
    @State private var teamMembers: [TeamMember] = []
    @State private var games: [Game] = []
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TeamMembersView(teamMembers: $teamMembers)
                .tabItem {
                    Label("Team Members", systemImage: "person.3.fill")
                }
                .tag(0)
            
            GamesView(games: $games)
                .tabItem {
                    Label("Games", systemImage: "sportscourt.fill")
                }
                .tag(1)
            
            ScheduleView(games: $games)
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
                .tag(2)
            
            SummaryView(teamMembers: teamMembers, games: games)
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
                .tag(3)
        }
        .onAppear {
            loadTeamMembers()
            loadGames()
        }
    }
    
    private func saveTeamMembers() {
        if let data = try? JSONEncoder().encode(teamMembers) {
            UserDefaults.standard.set(data, forKey: "teamMembers")
        }
    }
    
    private func loadTeamMembers() {
        if let data = UserDefaults.standard.data(forKey: "teamMembers"),
           let members = try? JSONDecoder().decode([TeamMember].self, from: data) {
            teamMembers = members
        }
    }
    
    private func saveGames() {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: "games")
        }
    }
    
    private func loadGames() {
        if let data = UserDefaults.standard.data(forKey: "games"),
           let savedGames = try? JSONDecoder().decode([Game].self, from: data) {
            games = savedGames
        }
    }
}

struct TeamMembersView: View {
    @Binding var teamMembers: [TeamMember]
    @State private var isShowingForm = false
    @State private var selectedMember: TeamMember? = nil
    @State private var showAlert = false
    @State private var deleteOffsets: IndexSet?

    var body: some View {
        NavigationView {
            ZStack {
                if teamMembers.isEmpty {
                    Text("No team members available. Add some!")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    List {
                        ForEach(teamMembers) { member in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(member.name)
                                        .font(.headline)
                                    Text("Position: \(member.position)")
                                    Text("Jersey #: \(member.jerseyNumber)")
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedMember = member
                                isShowingForm = true
                            }
                        }
                        .onDelete { offsets in
                            deleteOffsets = offsets
                            showAlert = true
                        }
                    }
                }
            }
            .navigationBarTitle("Team Members")
            .navigationBarItems(trailing: Button("Add") {
                selectedMember = nil
                isShowingForm = true
            })
            .sheet(isPresented: $isShowingForm) {
                TeamMemberFormView(
                    member: $selectedMember,
                    onSave: { saveMember($0) }
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Delete Member"),
                    message: Text("Are you sure you want to delete this member?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let deleteOffsets = deleteOffsets {
                            deleteMember(at: deleteOffsets)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func saveMember(_ member: TeamMember) {
        if let index = teamMembers.firstIndex(where: { $0.id == member.id }) {
            teamMembers[index] = member
        } else {
            teamMembers.append(member)
        }
        saveTeamMembers()
    }
    
    private func deleteMember(at offsets: IndexSet) {
        teamMembers.remove(atOffsets: offsets)
        saveTeamMembers()
    }
    
    private func saveTeamMembers() {
        if let data = try? JSONEncoder().encode(teamMembers) {
            UserDefaults.standard.set(data, forKey: "teamMembers")
        }
    }
}

struct TeamMemberFormView: View {
    @Binding var member: TeamMember?
    @State private var name: String = ""
    @State private var position: String = ""
    @State private var jerseyNumber: String = ""
    
    var onSave: (TeamMember) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                TextField("Position", text: $position)
                TextField("Jersey Number", text: $jerseyNumber)
                    .keyboardType(.numberPad)
            }
            .navigationBarTitle(member == nil ? "Add Member" : "Edit Member")
            .navigationBarItems(leading: Button("Cancel") {
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
            }, trailing: Button("Save") {
                let newMember = TeamMember(
                    id: member?.id ?? UUID(),
                    name: name,
                    position: position,
                    jerseyNumber: jerseyNumber,
                    attendance: member?.attendance ?? []
                )
                onSave(newMember)
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
            })
            .onAppear {
                if let member = member {
                    name = member.name
                    position = member.position
                    jerseyNumber = member.jerseyNumber
                }
            }
        }
    }
}

struct GamesView: View {
    @Binding var games: [Game]
    @State private var isShowingForm = false
    @State private var selectedGame: Game? = nil
    @State private var showAlert = false
    @State private var deleteOffsets: IndexSet?

    var body: some View {
        NavigationView {
            ZStack {
                if games.isEmpty {
                    Text("No games available. Add some!")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    List {
                        ForEach(games) { game in
                            VStack(alignment: .leading) {
                                Text(game.opponent)
                                    .font(.headline)
                                Text("Date: \(formattedDate(game.date))")
                                Text("Location: \(game.location)")
                                Text("Result: \(game.result)")
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedGame = game
                                isShowingForm = true
                            }
                        }
                        .onDelete { offsets in
                            deleteOffsets = offsets
                            showAlert = true
                        }
                    }
                }
            }
            .navigationBarTitle("Games")
            .navigationBarItems(trailing: Button("Add") {
                selectedGame = nil
                isShowingForm = true
            })
            .sheet(isPresented: $isShowingForm) {
                GameFormView(
                    game: $selectedGame,
                    onSave: { saveGame($0) }
                )
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Delete Game"),
                    message: Text("Are you sure you want to delete this game?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let deleteOffsets = deleteOffsets {
                            deleteGame(at: deleteOffsets)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    
    private func saveGame(_ game: Game) {
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games[index] = game
        } else {
            games.append(game)
        }
        saveGames()
    }
    
    private func deleteGame(at offsets: IndexSet) {
        games.remove(atOffsets: offsets)
        saveGames()
    }
    
    private func saveGames() {
        if let data = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(data, forKey: "games")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct GameFormView: View {
    @Binding var game: Game?
    @State private var opponent: String = ""
    @State private var location: String = ""
    @State private var result: String = "Win"
    @State private var notes: String = ""
    @State private var date: Date = Date()
    
    let results = ["Win", "Loss", "Draw", "Pending"]
    
    var onSave: (Game) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Opponent", text: $opponent)
                TextField("Location", text: $location)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Picker("Result", selection: $result) {
                    ForEach(results, id: \.self) {
                        Text($0)
                    }
                }
                TextField("Notes", text: $notes)
            }
            .navigationBarTitle(game == nil ? "Add Game" : "Edit Game")
            .navigationBarItems(leading: Button("Cancel") {
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
            }, trailing: Button("Save") {
                let newGame = Game(
                    id: game?.id ?? UUID(),
                    opponent: opponent,
                    date: date,
                    location: location,
                    result: result,
                    notes: notes
                )
                onSave(newGame)
                UIApplication.shared.windows.first?.rootViewController?.dismiss(animated: true)
            })
            .onAppear {
                if let game = game {
                    opponent = game.opponent
                    location = game.location
                    result = game.result
                    notes = game.notes
                    date = game.date
                }
            }
        }
    }
}

struct ScheduleView: View {
    @Binding var games: [Game]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(games.filter { $0.date >= Date() }) { game in
                    VStack(alignment: .leading) {
                        Text(game.opponent)
                            .font(.headline)
                        Text("Date: \(formattedDate(game.date))")
                        Text("Location: \(game.location)")
                    }
                }
            }
            .navigationBarTitle("Schedule")
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct SummaryView: View {
    var teamMembers: [TeamMember]
    var games: [Game]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Total Team Members: \(teamMembers.count)")
                Text("Total Games Played: \(games.count)")
                
                let totalWins = games.filter { $0.result.lowercased().contains("win") }.count
                Text("Total Wins: \(totalWins)")
                
                let totalLosses = games.filter { $0.result.lowercased().contains("loss") }.count
                Text("Total Losses: \(totalLosses)")
            }
            .navigationBarTitle("Summary")
            .padding()
        }
    }
}

@main
struct TeamManagementApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
