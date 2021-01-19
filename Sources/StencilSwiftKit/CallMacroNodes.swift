//
// StencilSwiftKit
// Copyright © 2019 SwiftGen
// MIT Licence
//

import Stencil

struct CallableBlock {
  let parameters: [String]
  let flags: [String]
  let nodes: [NodeType]

    init(parameters: [String], flags: [String] = [], nodes: [NodeType], token: Token? = nil) {
    self.parameters = parameters
    self.nodes = nodes
    self.flags = flags
  }

  func context(_ context: Context, arguments: [Resolvable], variable: Variable) throws -> [String: Any] {
    guard parameters.count == arguments.count else {
      throw TemplateSyntaxError(
        """
        Block '\(variable.variable)' accepts \(parameters.count) parameters, \
        \(arguments.count) given.
        """
      )
    }

    var result = [String: Any]()
    for (parameter, argument) in zip(parameters, arguments) {
      result[parameter] = try argument.resolve(context)
    }

    return result
  }
}

class MacroNode: NodeType {
  let variableName: String
  let parameters: [String]
  let flags: [String]
  let nodes: [NodeType]
  let token: Token?

  class func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
    let components = token.components
    guard components.count >= 2 else {
      throw TemplateSyntaxError("'macro' tag takes at least one argument, the name of the variable to set.")
    }
    let variable = components[1]
    var parameters = [String]()
    var flags = [String]()
    Array(components.dropFirst(2)).forEach { component in
        if component.starts(with: "-") || component.starts(with: "--") {
            flags.append(component)
        }
        else {
            parameters.append(component)
        }
    }

    let setNodes = try parser.parse(until(["endmacro"]))
    guard parser.nextToken() != nil else {
      throw TemplateSyntaxError("`endmacro` was not found.")
    }

    return MacroNode(variableName: variable, parameters: parameters, flags: flags, nodes: setNodes, token: token)
  }

  init(variableName: String, parameters: [String], flags: [String] = [], nodes: [NodeType], token: Token? = nil) {
    self.variableName = variableName
    self.parameters = parameters
    self.flags = flags
    self.nodes = nodes
    self.token = token
  }

  func render(_ context: Context) throws -> String {
    let block = CallableBlock(parameters: parameters, flags: flags, nodes: nodes, token: token)
    context[variableName] = block
    return ""
  }
}

class CallNode: NodeType {
  let variable: Variable
  let arguments: [Resolvable]
  let token: Token?

  class func parse(_ parser: TokenParser, token: Token) throws -> NodeType {
    let components = token.components
    guard components.count >= 2 else {
      throw TemplateSyntaxError("'call' tag takes at least one argument, the name of the block to call.")
    }

    let variable = Variable(components[1])
    let arguments = try Array(components.dropFirst(2)).map {
      try parser.compileResolvable($0, containedIn: token)
    }

    return CallNode(variable: variable, arguments: arguments, token: token)
  }

  init(variable: Variable, arguments: [Resolvable], token: Token? = nil) {
    self.variable = variable
    self.arguments = arguments
    self.token = token
  }

  func render(_ context: Context) throws -> String {
    let resolved = try variable.resolve(context)
    if let string = resolved as? String {
        return string
    }
    guard let block = resolved as? CallableBlock else {
      throw TemplateSyntaxError("Call to undefined block '\(variable.variable)'.")
    }
    let blockContext = try block.context(context, arguments: arguments, variable: variable)

    let result = try context.push(dictionary: blockContext) {
      try renderNodes(block.nodes, context)
    }
    if block.flags.contains("-p") || block.flags.contains("--prerendered") {
        context[variable.variable] = result
    }
    return result
  }
}
