import SwiftUI

struct GameReportView: View {
    let game: Game
    let store: GameStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Leaderboard
                    SectionHeader(title: "Final Rankings", icon: "list.number")
                    VStack(spacing: 12) {
                        ForEach(Array(game.rankings.enumerated()), id: \.element.playerID) { index, ranking in
                            if let player = store.player(for: ranking.playerID) {
                                RankingRow(rank: index + 1, name: player.name, score: ranking.total)
                            }
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Player Stats
                    SectionHeader(title: "Player Performance", icon: "chart.bar.fill")
                    VStack(spacing: 16) {
                        ForEach(game.playerIDs, id: \.self) { pid in
                            if let player = store.player(for: pid) {
                                let stats = calculateStats(for: pid)
                                PlayerStatsView(name: player.name, stats: stats)
                            }
                        }
                    }

                    // Game Details
                    SectionHeader(title: "Game Summary", icon: "info.circle.fill")
                    VStack(spacing: 12) {
                        SummaryRow(label: "Total Rounds", value: "\(game.rounds.count)")
                        SummaryRow(label: "Total Score", value: "\(game.totalScore)")
                        SummaryRow(label: "Created", value: game.createdAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Game Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func calculateStats(for playerID: UUID) -> PlayerStats {
        let scores = game.rounds.compactMap { $0.scores[playerID] }
        let total = scores.reduce(0, +)
        let average = scores.isEmpty ? 0 : Double(total) / Double(scores.count)
        let high = scores.max() ?? 0
        let low = scores.min() ?? 0
        return PlayerStats(total: total, average: average, highest: high, lowest: low)
    }
}

struct PlayerStats {
    let total: Int
    let average: Double
    let highest: Int
    let lowest: Int
}

struct PlayerStatsView: View {
    let name: String
    let stats: PlayerStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(name)
                .font(.headline)
            HStack(spacing: 0) {
                StatCard(label: "Average", value: String(format: "%.1f", stats.average))
                Divider()
                StatCard(label: "Highest", value: "\(stats.highest)")
                Divider()
                StatCard(label: "Lowest", value: "\(stats.lowest)")
            }
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.bold())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(title)
                .font(.title3.bold())
            Spacer()
        }
    }
}

struct RankingRow: View {
    let rank: Int
    let name: String
    let score: Int

    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.headline.bold())
                .frame(width: 30)
                .foregroundStyle(rank == 1 ? .yellow : .secondary)

            Text(name)
                .font(.body)

            Spacer()

            Text("\(score)")
                .font(.headline.bold())
                .foregroundStyle(score >= 0 ? .primary : .red)
        }
    }
}

struct SummaryRow: View {
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
