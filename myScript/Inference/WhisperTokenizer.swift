import Foundation

nonisolated final class WhisperTokenizer: Sendable {
    private let vocab: [Int: String]

    private static let specialTokenPrefixes = ["<|", ">>"]

    init(jsonURL: URL) throws {
        let data = try Data(contentsOf: jsonURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let model = json?["model"] as? [String: Any],
              let vocabDict = model["vocab"] as? [String: Int] else {
            throw TokenizerError.invalidFormat
        }

        // Build reverse mapping: token ID → string
        var reverseVocab = [Int: String]()
        for (token, tokenId) in vocabDict {
            reverseVocab[tokenId] = token
        }
        self.vocab = reverseVocab
    }

    func decode(tokenIds: [Int]) -> String {
        var pieces = [String]()

        for id in tokenIds {
            guard let token = vocab[id] else { continue }

            // Skip special tokens
            let isSpecial = Self.specialTokenPrefixes.contains(where: { token.hasPrefix($0) })
            if isSpecial { continue }

            pieces.append(token)
        }

        var text = pieces.joined()

        // Replace BPE space marker (Ġ → space)
        text = text.replacingOccurrences(of: "\u{0120}", with: " ")
        // Replace BPE newline marker
        text = text.replacingOccurrences(of: "\u{010A}", with: "\n")

        return text.trimmingCharacters(in: .whitespaces)
    }
}

nonisolated enum TokenizerError: LocalizedError {
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .invalidFormat: "Invalid tokenizer.json format"
        }
    }
}
