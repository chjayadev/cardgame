import SwiftUI

struct GameDetailView: View {
    @Binding var game: Game
    @ObservedObject var store: GameStore

    @State private var showingAddRound = false
    @State private var showingReport = false
    @State private var selectedRound: Round?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                ScoreboardHeaderView(game: game, store: store)
                Divider()
                RoundHistoryListView(game: game, store: store) { round in
                    selectedRound = round
                }
            }

            Button {
                showingAddRound = true
            } label: {
                Image(systemName: "plus")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .frame(width: 60, height: 60)
                    .background(Circle().fill(Color.blue))
                    .shadow(radius: 4)
            }
            .padding()
        }
        .navigationTitle(game.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack {
                    Button {
                        showingReport = true
                    } label: {
                        Label("Report", systemImage: "chart.bar.doc.horizontal")
                    }

                    Menu {
                        Button(role: .destructive) {
                            store.resetGame(game.id)
                        } label: {
                            Label("Reset Game", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddRound) {
            AddRoundView(players: game.playerIDs.compactMap { store.player(for: $0) }) { scores in
                store.addRound(to: game.id, scores: scores)
            }
        }
        .sheet(isPresented: $showingReport) {
            GameReportView(game: game, store: store)
        }
        .sheet(item: $selectedRound) { round in
            let players = game.playerIDs.compactMap { store.player(for: $0) }
            let roundNumber = (game.rounds.firstIndex(where: { $0.id == round.id }) ?? 0) + 1
            RoundDetailView(round: round, players: players, roundNumber: roundNumber)
        }
    }
}

// MARK: - Subviews

struct ScoreboardHeaderView: View {
    let game: Game
    let store: GameStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 24) {
                ForEach(game.rankings, id: \.playerID) { ranking in
                    if let player = store.player(for: ranking.playerID) {
                        VStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Text(player.name)
                                    .font(.subheadline.bold())
                                if ranking.playerID == game.leader && game.totalScore != 0 {
                                    Image(systemName: "crown.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.yellow)
                                }
                            }
                            .lineLimit(1)

                            Text("\(ranking.total)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(ranking.total >= 0 ? Color.primary : Color.red)
                        }
                        .frame(minWidth: 80)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

struct RoundHistoryListView: View {
    let game: Game
    let store: GameStore
    let onSelect: (Round) -> Void

    var body: some View {
        Group {
            if game.rounds.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 64))
                        .foregroundStyle(.tertiary)
                    Text("No Rounds Recorded")
                        .font(.headline)
                    Text("Tap the + button to add your first round.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List {
                    let enumeratedRounds = Array(game.rounds.enumerated().reversed())
                    ForEach(enumeratedRounds, id: \.element.id) { index, round in
                        Button {
                            onSelect(round)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Round \(index + 1)")
                                        .font(.headline)
                                    Text(round.timestamp.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        let correctedOffsets = IndexSet(offsets.map { game.rounds.count - 1 - $0 })
                        store.deleteRounds(from: game.id, at: correctedOffsets)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

struct RoundDetailView: View {
    let round: Round
    let players: [Player]
    let roundNumber: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(players, id: \.id) { player in
                        HStack {
                            Text(player.name)
                                .font(.headline)
                            Spacer()
                            let score = round.scores[player.id] ?? 0
                            Text("\(score)")
                                .font(.title3.bold())
                                .foregroundStyle(score >= 0 ? Color.primary : Color.red)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Scores")
                } footer: {
                    Text("Recorded at \(round.timestamp.formatted(date: .abbreviated, time: .shortened))")
                }
            }
            .navigationTitle("Round \(roundNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct AddRoundView: View {
    let players: [Player]
    let onSave: ([UUID: Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scores: [UUID: String] = [:]
    @FocusState private var focusedPlayer: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(players, id: \.id) { player in
                        HStack {
                            Text(player.name)
                                .font(.headline)
                            Spacer()
                            TextField("0", text: binding(for: player.id))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .focused($focusedPlayer, equals: player.id)
                        }
                    }
                } header: {
                    Text("Enter Round Scores")
                }
            }
            .navigationTitle("New Round")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        save()
                    }
                    .fontWeight(.bold)
                }
            }
            .onAppear {
                focusedPlayer = players.first?.id
            }
        }
    }

    private func binding(for id: UUID) -> Binding<String> {
        Binding(
            get: { scores[id, default: ""] },
            set: { scores[id] = $0 }
        )
    }

    private func save() {
        var finalScores: [UUID: Int] = [:]
        for player in players {
            finalScores[player.id] = Int(scores[player.id] ?? "0") ?? 0
        }
        onSave(finalScores)
        dismiss()
    }
}

struct GameReportView: View {
    let game: Game
    let store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Final Rankings")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(game.rankings.enumerated()), id: \.element.playerID) { index, ranking in
                            if let player = store.player(for: ranking.playerID) {
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.headline.bold())
                                        .frame(width: 30)
                                    Text(player.name)
                                    Spacer()
                                    Text("\(ranking.total)")
                                        .bold()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)

                    SummaryRow_Local(label: "Total Rounds", value: "\(game.rounds.count)")
                    SummaryRow_Local(label: "Total Score", value: "\(game.totalScore)")
                }
                .padding()
            }
            .navigationTitle("Game Report")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SummaryRow_Local: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}
