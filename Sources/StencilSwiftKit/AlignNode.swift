//
// StencilSwiftKit
// Copyright © 2021 Rosberry
// MIT Licence
//

import Stencil

class AlignNode: NodeType {

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
                    throw TemplateSyntaxError("`anchor` tag defined more then once inside `align` block")
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
        let nodes = try parser.parse(until(["endalign"]))

        guard let token = parser.nextToken() else {
          throw TemplateSyntaxError("`endalign` was not found.")
        }

        if token.contents == "empty" {
          _ = parser.nextToken()
        }
        return AlignNode(nodes: nodes)
    }

}
