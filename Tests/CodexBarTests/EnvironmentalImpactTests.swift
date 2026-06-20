import Foundation
import Testing
@testable import CodexBar
@testable import CodexBarCore

struct EnvironmentalImpactTests {
    @Test
    func unapprovedMethodologyIsDisabledByDefault() {
        #expect(!EnvironmentalImpact.methodologyIsEnabled(environment: [:]))

        let breakdowns = [CostUsageDailyReport.ModelBreakdown(
            modelName: "mistral-large-latest",
            costUSD: nil,
            totalTokens: 10000)]
        #expect(EnvironmentalImpact(provider: .mistral, breakdowns: breakdowns, environment: [:]) == nil)
    }

    @Test
    func debugMethodologyPreviewRequiresExplicitOptIn() {
        #if DEBUG
        #expect(EnvironmentalImpact.methodologyIsEnabled(environment: [
            EnvironmentalImpact.previewEnvironmentKey: "1",
        ]))
        #expect(!EnvironmentalImpact.methodologyIsEnabled(environment: [
            EnvironmentalImpact.previewEnvironmentKey: "true",
        ]))
        #else
        #expect(!EnvironmentalImpact.methodologyIsEnabled(environment: [
            EnvironmentalImpact.previewEnvironmentKey: "1",
        ]))
        #endif
    }

    @Test
    func debugPreviewShowsSupportedModelsAndSuppressesUnsupportedModels() throws {
        #if DEBUG
        let environment = [EnvironmentalImpact.previewEnvironmentKey: "1"]
        let supportedEntry = Self.entry(modelName: "mistral-large-latest")
        let supportedSnapshot = CostUsageTokenSnapshot(
            sessionTokens: supportedEntry.totalTokens,
            sessionCostUSD: 1,
            last30DaysTokens: supportedEntry.totalTokens,
            last30DaysCostUSD: 1,
            daily: [supportedEntry],
            sessionDay: supportedEntry,
            updatedAt: Date())
        let supportedSection = try #require(UsageMenuCardView.Model.tokenUsageSection(
            provider: .mistral,
            enabled: true,
            snapshot: supportedSnapshot,
            error: nil,
            environment: environment))

        #expect(supportedSection.environmentalImpactLines.map(\.id) == [
            .energyToday,
            .co2Today,
            .energyWindow,
            .co2Window,
        ])

        let unsupportedEntry = Self.entry(modelName: "unsupported-model")
        let unsupportedSnapshot = CostUsageTokenSnapshot(
            sessionTokens: unsupportedEntry.totalTokens,
            sessionCostUSD: 1,
            last30DaysTokens: unsupportedEntry.totalTokens,
            last30DaysCostUSD: 1,
            daily: [unsupportedEntry],
            sessionDay: unsupportedEntry,
            updatedAt: Date())
        let unsupportedSection = try #require(UsageMenuCardView.Model.tokenUsageSection(
            provider: .mistral,
            enabled: true,
            snapshot: unsupportedSnapshot,
            error: nil,
            environment: environment))

        #expect(unsupportedSection.environmentalImpactLines.isEmpty)
        #endif
    }

    @Test
    func energyFormatting() {
        // Less than 1 kWh (formatted as Wh)
        #expect(UsageFormatter.formatEnergy(0.0015) == "1.5 Wh")
        #expect(UsageFormatter.formatEnergy(0.0125) == "13 Wh")
        #expect(UsageFormatter.formatEnergy(0.999) == "999 Wh")

        // Greater than or equal to 1 kWh (formatted as kWh)
        #expect(UsageFormatter.formatEnergy(1.0) == "1 kWh")
        #expect(UsageFormatter.formatEnergy(1.52) == "1.5 kWh")
        #expect(UsageFormatter.formatEnergy(12.45) == "12 kWh")
    }

    @Test
    func cO2Formatting() {
        // Less than 1 kg (formatted as g)
        #expect(UsageFormatter.formatCO2(0.0015) == "1.5 g")
        #expect(UsageFormatter.formatCO2(0.0125) == "13 g")
        #expect(UsageFormatter.formatCO2(0.999) == "999 g")

        // Greater than or equal to 1 kg (formatted as kg)
        #expect(UsageFormatter.formatCO2(1.0) == "1 kg")
        #expect(UsageFormatter.formatCO2(1.52) == "1.5 kg")
        #expect(UsageFormatter.formatCO2(12.45) == "12 kg")
    }

    @Test
    func environmentalRowsKeepStableIdentityWhenTextMatches() {
        let duplicateText = "Today: 1.5 Wh (0 phone charges / 0 kettle boils)"
        let rows = [
            UsageMenuCardView.Model.EnvironmentalImpactLine(id: .energyToday, text: duplicateText),
            UsageMenuCardView.Model.EnvironmentalImpactLine(id: .energyWindow, text: duplicateText),
        ]

        #expect(rows.map(\.text) == [duplicateText, duplicateText])
        #expect(rows.map(\.id) == [.energyToday, .energyWindow])
        #expect(Set(rows.map(\.id)).count == rows.count)
    }

    private static func entry(modelName: String) -> CostUsageDailyReport.Entry {
        CostUsageDailyReport.Entry(
            date: "2026-06-20",
            inputTokens: 8000,
            outputTokens: 2000,
            totalTokens: 10000,
            costUSD: 1,
            modelsUsed: [modelName],
            modelBreakdowns: [CostUsageDailyReport.ModelBreakdown(
                modelName: modelName,
                costUSD: 1,
                totalTokens: 10000)])
    }
}
