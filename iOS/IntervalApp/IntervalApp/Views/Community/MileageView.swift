//
//  MileageView.swift
//  IntervalApp
//
//  Created by Claude on 2024.
//

import SwiftUI

struct MileageView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var mileageManager = MileageManager.shared
    @ObservedObject private var adManager = AdManager.shared

    @State private var isClaimingReward = false
    @State private var showingRewardSuccess = false
    @State private var showingRewardError = false
    @State private var rewardErrorMessage: String?
    @State private var earnedAmount: Int = 0

    var body: some View {
        List {
            // Balance Section
            Section {
                balanceCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Ad Reward Section
            Section {
                adRewardButton
            } header: {
                Text("Earn Mileage")
            }

            // Summary Section
            Section {
                HStack {
                    Text("Total Earned")
                    Spacer()
                    Text(mileageManager.balance?.formattedTotalEarned ?? "0M")
                        .foregroundStyle(.green)
                }

                HStack {
                    Text("Total Spent")
                    Spacer()
                    Text(mileageManager.balance?.formattedTotalSpent ?? "0M")
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Summary")
            }

            // Transactions Section
            Section {
                if mileageManager.transactions.isEmpty && !mileageManager.isLoading {
                    Text("No transactions yet")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    ForEach(mileageManager.transactions) { transaction in
                        transactionRow(transaction)
                    }

                    if mileageManager.hasMorePages {
                        Button {
                            Task {
                                await mileageManager.loadMoreIfNeeded()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                if mileageManager.isLoading {
                                    ProgressView()
                                } else {
                                    Text("Load More")
                                }
                                Spacer()
                            }
                        }
                    }
                }
            } header: {
                Text("Transaction History")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(String(localized: "Mileage"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(String(localized: "Done")) {
                    dismiss()
                }
            }
        }
        .refreshable {
            await mileageManager.refresh()
        }
        .task {
            await mileageManager.refresh()
        }
        .alert("Reward Earned!", isPresented: $showingRewardSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You earned \(earnedAmount)M!")
        }
        .alert("Error", isPresented: $showingRewardError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(rewardErrorMessage ?? "Failed to claim reward")
        }
    }

    // MARK: - Ad Reward Button

    private var adRewardButton: some View {
        Button {
            watchAdAndClaimReward()
        } label: {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .font(.title2)
                    .foregroundStyle(mileageManager.adRemainingCount > 0 ? .orange : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Watch Ad & Earn")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("Remaining: \(mileageManager.adRemainingCount)/\(mileageManager.adDailyLimit) today")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isClaimingReward || adManager.isLoadingRewardedAd {
                    ProgressView()
                } else if mileageManager.adRemainingCount > 0 {
                    Text("+50M")
                        .font(.headline)
                        .foregroundStyle(.orange)
                } else {
                    Text("Done")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(!adManager.isRewardedAdReady || isClaimingReward || mileageManager.adRemainingCount <= 0)
    }

    private func watchAdAndClaimReward() {
        guard adManager.isRewardedAdReady, mileageManager.adRemainingCount > 0 else { return }

        isClaimingReward = true

        adManager.showRewardedAd { success in
            if success {
                // 광고 시청 완료 - 서버에 보상 요청
                Task {
                    do {
                        let reward = try await mileageManager.claimAdReward()
                        earnedAmount = reward
                        showingRewardSuccess = true
                        // 히스토리 및 광고 상태 새로고침
                        await mileageManager.fetchHistory(page: 1)
                        await mileageManager.fetchAdStatus()
                    } catch {
                        rewardErrorMessage = error.localizedDescription
                        showingRewardError = true
                    }
                    isClaimingReward = false
                }
            } else {
                isClaimingReward = false
            }
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 8) {
            Text("Current Balance")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(mileageManager.balance?.formattedBalance ?? "0M")
                .font(.system(size: 48, weight: .bold))

            Text("M = Mileage Points")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.15), .yellow.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
    }

    // MARK: - Transaction Row

    private func transactionRow(_ transaction: MileageTransaction) -> some View {
        HStack {
            // Icon
            Image(systemName: transaction.type.icon)
                .font(.title3)
                .foregroundStyle(transaction.type.isPositive ? .green : .red)
                .frame(width: 32)

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.description ?? transaction.type.displayName)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(transaction.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount
            VStack(alignment: .trailing, spacing: 2) {
                Text(transaction.formattedAmount)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(transaction.type.isPositive ? .green : .red)

                Text(transaction.formattedBalanceAfter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        MileageView()
    }
}
