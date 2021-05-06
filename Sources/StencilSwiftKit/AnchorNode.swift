//
// StencilSwiftKit
// Copyright © 2021 Rosberry
// MIT Licence
//

import Stencil

class AnchorNode: NodeType {

    var token: Token?

    init(token: Token) {
        self.token = token
    }

    func render(_ context: Context) throws -> String {
        return ""
    }

    class func parse(parser: TokenParser, token: Token) throws -> NodeType {
        return AnchorNode(token: token)
    }
}
