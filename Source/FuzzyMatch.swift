//
//  FuzzyMatch.swift
//  Menuet
//
//

import Foundation


enum FuzzyMatch {

  struct Match {
    let score: Int
    let matchedIndices: [Int]
  }

  // Bonus for a match that is immediately preceded by another match.
  // Rewards contiguous runs ("copy" scoring higher against "Copy" than
  // against "Cancel Operation Pyx Yarn"). Larger value = stronger
  // preference for unbroken substrings over scattered hits.
  private static let sequentialBonus = 15

  // Bonus when the match falls right after a separator character (space,
  // ">", "_", etc. — see `isSeparator`). Strongly favors word-start
  // matches: "of" → "**O**pen **F**ile" beats "C**o**de o**f** conduct".
  // Largest single signal in the model — word boundaries are the most
  // semantically meaningful match positions in menu titles.
  private static let separatorBonus = 30

  // Bonus when the match is at an uppercase letter immediately following
  // a lowercase letter — i.e., a camelCase boundary. Lets "of" rank
  // "**O**pen**F**older" above "**o**pen**f**older". Same magnitude as
  // separatorBonus because both signal a "word start" in different
  // naming conventions.
  private static let camelBonus = 30

  // Bonus when the first matched character is at index 0 of the
  // candidate. Encodes the prefix-match preference users expect from
  // search ("co" → "**Co**py" before "Open **Co**py"). Smaller than
  // word-boundary bonuses because prefix-ness is already partially
  // rewarded by the absence of the leading-letter penalty below.
  private static let firstLetterBonus = 15

  // Per-character penalty applied to characters before the first match.
  // Mild push toward earlier matches when no stronger signal applies.
  // Capped by `maxLeadingLetterPenalty` so very long candidates with a
  // late first match aren't crushed beyond recovery.
  private static let leadingLetterPenalty = -5
  private static let maxLeadingLetterPenalty = -15

  // Per-character penalty applied to candidate characters that did not
  // participate in the match. Keeps shorter candidates competitive with
  // longer ones at equal positional quality — "Copy" outranks "Copy
  // Special Long Name" for query "co" almost entirely via this term.
  private static let unmatchedLetterPenalty = -1

  static func score(query: String, candidate: String, caseSensitive: Bool) -> Match? {
    guard !query.isEmpty, !candidate.isEmpty else { return nil }

    let queryChars = Array(query)
    let candidateChars = Array(candidate)
    let equal: (Character, Character) -> Bool = caseSensitive
      ? { $0 == $1 }
      : { $0.lowercased() == $1.lowercased() }

    var matchedIndices: [Int] = []
    matchedIndices.reserveCapacity(queryChars.count)
    var queryIndex = 0
    for (candidateIndex, c) in candidateChars.enumerated() {
      if queryIndex < queryChars.count && equal(queryChars[queryIndex], c) {
        matchedIndices.append(candidateIndex)
        queryIndex += 1
      }
    }
    guard queryIndex == queryChars.count else { return nil }

    var score = 0
    let firstMatch = matchedIndices[0]
    score += max(maxLeadingLetterPenalty, leadingLetterPenalty * firstMatch)
    score += unmatchedLetterPenalty * (candidateChars.count - matchedIndices.count)

    for (i, candidateIndex) in matchedIndices.enumerated() {
      if i > 0 && matchedIndices[i - 1] == candidateIndex - 1 {
        score += sequentialBonus
      }
      if candidateIndex == 0 {
        score += firstLetterBonus
      } else {
        let prev = candidateChars[candidateIndex - 1]
        let curr = candidateChars[candidateIndex]
        if isSeparator(prev) {
          score += separatorBonus
        } else if prev.isLowercase && curr.isUppercase {
          score += camelBonus
        }
      }
    }

    return Match(score: score, matchedIndices: matchedIndices)
  }

  private static func isSeparator(_ c: Character) -> Bool {
    return c == " " || c == "_" || c == "-" || c == "." || c == ">" || c == "/"
  }
}
