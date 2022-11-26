//
//  Trie.swift
//  MenuFinder
//
//  Created by Jesse Kasky on 7/10/17.
//  Copyright © 2017 Codjax. All rights reserved.
//

import Foundation


fileprivate class TrieNode<V> {

  let character: Character
  var children: [TrieNode<V>]
  var value: V?

  var isLeaf: Bool {
    get {
      return value != nil
    }
  }

  init(character: Character, value: V? = nil) {
    self.character = character
    self.value = value
    self.children = []
  }
  
  func countLeafs() -> Int {
    if children.count == 0 {
      return 1
    }
    var count = 0
    for child in children {
      count += child.countLeafs()
    }
    return count
  }
  
  func countNodes() -> Int {
    var count = children.count
    for child in children {
      count += child.countNodes()
    }
    return count
  }
}


/**
 * Trie structure for matching character sequences to any object.
 *
 * A slightly different Trie than a prefix trie, this Trie matches sequences
 * of characters that are not adjacent and they do not need to be prefixes.
 */
public class Trie<V> {

  private let root: TrieNode<V>
  private var nodeCount: Int

  init() {
    root = TrieNode<V>(character: "\u{0}")
    nodeCount = 0
  }

  var count: Int {
    return root.countLeafs();
  }
  
  /**
   * Inserts a new value into the trie with a given label.
   */
  func insert(label: String, value: V) {
    var node = root
    for c in label {
      if node.children.isEmpty {
        let newChild = TrieNode<V>(character:c)
        node.children.append(newChild)
        node = newChild
        continue
      }
      for i in 0..<node.children.count {
        let child = node.children[i]
        if child.character == c {
          node = child
          break
        }
        if c < child.character {
          let newChild = TrieNode<V>(character:c)
          node.children.insert(newChild, at:i)
          node = newChild
          break
        }
        if i == node.children.count - 1 {
          let newChild = TrieNode<V>(character:c)
          node.children.append(newChild)
          node = newChild
          break
        }
      }
    }
    node.value = value
    nodeCount += 1
  }

  /**
   * Finds all values in the trie with labels that match the given sequence.
   *
   * The characters in the sequence can be nonadjacent to match a label. All of
   * the sequence characters must be in the label to match. The results will be
   * returned in ascending alphabetical order
   */
  func find(sequence: String) -> [V] {
    return find(sequence, root, { $0 == $1 }).map { $0.value! }
  }

  func find(sequence: String, match: (Character, Character) -> Bool) -> [V] {
    return find(sequence, root, match).map { $0.value! }
  }

  private func find(_ sequence: String, _ node: TrieNode<V>, _ match: (Character, Character) -> Bool) -> [TrieNode<V>] {
    var matches: [TrieNode<V>] = []

    // When there is no more sequence return all leafs. This indicates that
    // a full match has been made up to this point so traverse the remaining
    // children to find all the leafs.
    guard sequence.count > 0 else {
      for child in node.children {
        if child.isLeaf {
          matches.append(child)
        }
        if child.children.count > 0 {
          matches += find(sequence, child, match)
        }
      }
      return matches
    }

    // When the first character of the sequence matches the current node we have
    // a partial match.
    if match(sequence[sequence.startIndex], node.character) {
      if node.isLeaf {
        matches.append(node)
      }
      if sequence.count > 1 {
        let suffix = sequence.suffix(sequence.count - 1)
        if node.children.count == 0 {
          return []
        }
        for child in node.children {
          matches += find(String(suffix), child, match)
        }
      } else {
        matches += find("", node, match)
      }
    } else {
      for child in node.children {
        matches += find(sequence, child, match)
      }
    }
    return matches
  }
}
