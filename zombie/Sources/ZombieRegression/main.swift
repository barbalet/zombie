import Foundation
import ZombieCore

let catalog: ZombieScenarioCatalog
if let index = CommandLine.arguments.firstIndex(of: "--catalog"),
   CommandLine.arguments.indices.contains(index + 1) {
    catalog = try ScenarioCatalog.load(from: URL(fileURLWithPath: CommandLine.arguments[index + 1]))
} else {
    catalog = try ScenarioCatalog.bundled()
}

let validation = ScenarioCatalog.validate(catalog)
let errors = validation.filter { $0.severity == .error }
for issue in validation {
    print(issue.description)
}

let includeDeferred = CommandLine.arguments.contains("--include-deferred")
let simulator = ZombieSkirmishSimulator()
let results = simulator.runCatalog(catalog, includeDeferred: includeDeferred)
for result in results {
    print("\(result.passed ? "PASS" : "FAIL") \(result.scenarioID) \(result.tier.rawValue) turns=\(result.turns) events=\(result.events.count) outcome=\(result.outcome)")
    if CommandLine.arguments.contains("--jsonl") {
        print((try? ScenarioEventExporter.jsonLines(for: result)) ?? "")
    }
}

let failedResults = results.filter { !$0.passed }
print("zombie regression: \(results.count) scenario(s), \(failedResults.count) failed, \(errors.count) validation error(s)")
print(DiagnosticReport.manifest(catalog: catalog, results: results))

if !errors.isEmpty || !failedResults.isEmpty {
    exit(1)
}
