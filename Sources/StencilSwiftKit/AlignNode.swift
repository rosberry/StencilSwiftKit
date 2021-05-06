//
// StencilSwiftKit
// Copyright © 2021 Rosberry
// MIT Licence
//

import Stencil

class AlignNode: NodeType {

    enum Error: Swift.Error {
        case unexpectedAnchor
    }

    var token: Token?

    let nodes: [NodeType]
    init(nodes: [NodeType]) {
        self.nodes = nodes
    }

    func render(_ context: Context) throws -> String {
        var result = ""
        var anchorIndex = 0
        try nodes.forEach { node in
            if node is AnchorNode {
                guard anchorIndex == 0 else {
                    throw Error.unexpectedAnchor
                }
                anchorIndex = result.count
            }
            else {
                result += try node.render(context)
            }
        }
        var components = result.split(separator: "\n").map({String($0)})
        guard components.count > 1 else {
            return result
        }
        let alignString = Array(0..<anchorIndex).map({ _ in " " }).joined()
        for i in 1..<components.count {
            components[i] = alignString + components[i].trimmingCharacters(in: .whitespaces)
        }
        result = components.joined(separator: "\n")
        return result
    }

    class func parse(parser: TokenParser, token: Token) throws -> NodeType {
        let nodes = try parser.parse(until(["endalign", "empty"]))
        return AlignNode(nodes: nodes)
    }

}
