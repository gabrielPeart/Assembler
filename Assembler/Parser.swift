//
//  Parser.swift
//  Assembler
//
//  Created by Ulrik Damm on 08/09/2016.
//  Copyright © 2016 Ufd.dk. All rights reserved.
//

struct State {
	let source : String
	let location : String.Index
	
	init(source : String, location : String.Index) {
		self.source = source
		self.location = location
	}
	
	init(source : [String]) {
		self.source = source.joined(separator: "\n")
		self.location = self.source.startIndex
	}
	
	init(source : String) {
		self.source = source
		self.location = source.startIndex
	}
	
	var atEnd : Bool {
		return location == source.endIndex
	}
	
	func getAt(location : String.Index) -> Character? {
		guard location < source.endIndex else { return nil }
		return source[location]
	}
	
	func getChar(ignoreComments : Bool = true) -> (value : Character, state : State)? {
		guard var next = getAt(location: location) else { return nil }
		var nextLocation = source.index(after: location)
		
		if next == "#" {
			while true {
				nextLocation = source.index(after: nextLocation)
				guard let c = getAt(location: nextLocation) else { return nil }
				if c == "\n" {
					next = c
					break
				}
			}
		}
		
		let state = State(source: source, location: nextLocation)
		return (next, state)
	}
	
	func getNumericChar() -> (value : String, state : State)? {
		if let (c, state) = getChar(), c.isNumeric { return (String(c), state) }
		return nil
	}
	
	func getAlphaChar() -> (value : String, state : State)? {
		if let (c, state) = getChar(), c.isAlpha { return (String(c), state) }
		return nil
	}
	
	func getAlphaOrNumericChar() -> (value : String, state : State)? {
		return getAlphaChar() ?? getNumericChar()
	}
	
	func getString() -> (value : String, state : State)? {
		var state = ignoreWhitespace()
		var string = ""
		
		while let (char, newState) = state.getAlphaChar() {
			string += char
			state = newState
		}
		
		guard string != "" else { return nil }
		return (string, state)
	}
	
	func getUntil(end : String) -> (value : String, state : State)? {
		var state = self
		var string = ""
		
		while true {
			if let newState = state.match(string: end) {
				return (string, newState)
			}
			
			guard let (c, newState) = state.getChar() else { return nil }
			state = newState
			string += String(c)
		}
	}
	
	func get(predicate : (State) -> (String, State)?) -> (value : String, state : State)? {
		var state = ignoreWhitespace()
		var string = ""
		
		while let (char, newState) = predicate(state) {
			string += char
			state = newState
		}
		
		guard string != "" else { return nil }
		return (string, state)
	}
	
	func getIdentifier() -> (value : String, state : State)? {
		var state = ignoreWhitespace()
		
		guard let (char, newState) = state.getAlphaChar() else { return nil }
		var string = char
		state = newState
		
		while let (char, newState) = state.getAlphaChar() ?? state.getNumericChar() {
			string += char
			state = newState
		}
		
		return (string, state)
	}
	
	func getNumber() -> (value : Int, state : State)? {
		var state = ignoreWhitespace()
		
		if let (z, newState) = state.getChar(), z == "0" {
			state = newState
			
			if let (c, newState) = state.getChar(), c == "d" {
				state = newState
				return state.getDecimalNumber()
			}
			
			if let (c, newState) = state.getChar(), c == "x" {
				state = newState
				return state.getHexNumber()
			}
			
			return nil
		} else {
			return state.getDecimalNumber()
		}
	}
	
	func getHexNumber() -> (value : Int, state : State)? {
		var state = self
		
		guard let (char, newState) = state.getChar(), char.isHex else { return nil }
		var string = String(char)
		state = newState
		
		while let (char, newState) = state.getChar(), char.isHex {
			string += String(char)
			state = newState
		}
		
		return (Int(string, radix: 16)!, state)
	}
	
	func getDecimalNumber() -> (value : Int, state : State)? {
		var state = self
		
		guard let (char, newState) = state.getNumericChar() else { return nil }
		var string = char
		state = newState
		
		while let (char, newState) = state.getNumericChar() {
			string += char
			state = newState
		}
		
		return (Int(string)!, state)
	}
	
	func ignoreWhitespace(allowNewline : Bool = false) -> State {
		guard let (char, state) = getChar(), char.isWhitespace || (allowNewline && char == "\n") else { return self }
		return state.ignoreWhitespace(allowNewline: allowNewline)
	}
	
	func match(string : String) -> State? {
		var state = self
		for character in string.characters {
			guard let (c, newState) = state.getChar(), character == c else { return nil }
			state = newState
		}
		return state
	}
	
	func getKeyword(keyword : String) -> State? {
		guard let (string, state) = getString() else { return nil }
		guard string == keyword else { return nil }
		return state
	}
	
	func getSeparator() -> State? {
		let state = ignoreWhitespace(allowNewline: false)
		if state.atEnd { return state }
		guard let (c, state1) = state.getChar(), c == "\n" || c == ";" else { return nil }
		return state1.getSeparator() ?? state1
	}
	
	func getStringLiteral() -> (value : String, state : State)? {
		var state = ignoreWhitespace()
		
		guard let (c, newState1) = state.getChar(), c == "\"" else { return nil }
		state = newState1
		
		guard let (string, newState2) = state.getUntil(end: "\"") else { return nil }
		return (string, newState2)
	}
	
	func getInstruction() -> (value : Instruction, state : State)? {
		var state = ignoreWhitespace(allowNewline: true)
		
		var operands : [Expression] = []
		
		guard let (mnemonic, newState1) = state.getIdentifier() else { return nil }
		state = newState1
		
		while let (op, newState2) = state.getExpression() {
			state = newState2
			operands.append(op)
			
			if let (char, newState3) = state.ignoreWhitespace().getChar(), char == "," {
				state = newState3
			} else {
				break
			}
		}
		
		guard let newState2 = state.getSeparator() else { return nil }
		state = newState2
		
		let instruction = Instruction(mnemonic: mnemonic, operands: operands)
		return (instruction, state)
	}
	
	func getInstructionList() -> (value : [Instruction], state : State)? {
		var state = ignoreWhitespace()
		var instructions : [Instruction] = []
		
		while let (instruction, newState) = state.getInstruction() {
			instructions.append(instruction)
			state = newState
		}
		
		guard !instructions.isEmpty else { return nil }
		return (instructions, state)
	}
	
	func getLabel() -> (value : Label, state : State)? {
		var state = ignoreWhitespace(allowNewline: true)
		let options : [String: Expression]
		
		if let (optionList, newState0) = state.getOptionList() {
			state = newState0
			options = optionList
		} else {
			options = [:]
		}
		
		state = state.ignoreWhitespace(allowNewline: true)
		
		guard let (name, newState1) = state.getIdentifier() else { return nil }
		state = newState1
		
		guard let (c, newState2) = state.getChar(), c == ":" else { return nil }
		state = newState2
		
		guard let (instructions, newState3) = state.getInstructionList() else { return nil }
		state = newState3
		
		let label = Label(identifier: name, instructions: instructions, options: options)
		return (label, state)
	}
	
	func getDefine() -> (value : (name : String, constant : Expression), state : State)? {
		var state = ignoreWhitespace()
		
		guard let (identifier, newState1) = state.getIdentifier() else { return nil }
		state = newState1
		
		guard let (c, newState2) = state.ignoreWhitespace().getChar(), c == "=" else { return nil }
		state = newState2
		
		guard let (value, newState3) = state.getExpression() else { return nil }
		state = newState3
		
		guard let newState4 = state.getSeparator() else { return nil /* Expected separator */ }
		state = newState4
		
		return ((identifier, value), state)
	}
	
	func getProgram() throws -> (value : Program, state : State)? {
		var state = ignoreWhitespace()
		var labels : [Label] = []
		var constants : [String: Expression] = [:]
		
		while true {
			if let (label, newState) = state.getLabel() {
				labels.append(label)
				state = newState
			} else if let (define, newState) = state.getDefine() {
				guard !constants.keys.contains(define.name) else {
					throw ErrorMessage("Constant already defined")
				}
				
				state = newState
				constants[define.name] = define.constant
			} else {
				break
			}
		}
		
		guard !labels.isEmpty else { return nil }
		let program = Program(constants: constants, blocks: labels)
		return (program, state)
	}
	
	func getOptionList() -> (value : [String: Expression], state : State)? {
		var state = ignoreWhitespace()
		var options : [String: Expression] = [:]
		
		guard let (c1, newState1) = state.getChar(), c1 == "[" else { return nil }
		state = newState1
		
		if let (option, newState2) = state.getOption() {
			state = newState2
			options[option.key] = option.value
		}
		
		guard let (c2, newState3) = state.getChar(), c2 == "]" else { return nil }
		state = newState3
		
		return (options, state)
	}
	
	func getOption() -> (value : (key : String, value : Expression), state : State)? {
		var state = ignoreWhitespace()
		
		guard let (key, newState1) = state.getIdentifier() else { return nil }
		state = newState1
		
		guard let (c, newState2) = state.getChar(), c == "(" else { return nil }
		state = newState2
		
		let value : Expression
		if let (number, newState3) = state.getExpression() {
			state = newState3
			value = number
		} else {
			return nil
		}
		
		guard let (c2, newState4) = state.getChar(), c2 == ")" else { return nil }
		state = newState4
		
		return ((key, value), state)
	}
	
	func getExpression() -> (value : Expression, state : State)? {
		var state = ignoreWhitespace()
		
		let expression : Expression
		
		if let (constant, newState1) = state.getIdentifier() {
			state = newState1
			expression = Expression.constant(constant)
		} else if let (string, newState1) = state.getStringLiteral() {
			state = newState1
			expression = .string(string)
		} else if let (number, newState1) = state.getNumber() {
			state = newState1
			expression = .value(number)
		} else if let (c, newState1) = state.ignoreWhitespace().getChar(), c == "(" {
			state = newState1
			guard let (nextExpression, newState2) = state.getExpression() else { return nil /* exprected expression */ }
			state = newState2
			guard let (c2, newState3) = state.ignoreWhitespace().getChar(), c2 == ")" else { return nil /* exprected ) */ }
			state = newState3
			expression = .parens(nextExpression)
		} else if let (op, newState1) = state.getExpressionOperator() {
			state = newState1
			guard let (nextExpression, newState2) = state.getExpression() else { return nil /* Expected expression */ }
			state = newState2
			expression = .prefix(op, nextExpression)
		} else {
			return nil
		}
		
		if let (operatorCharacter, newState2) = state.getExpressionOperator() {
			state = newState2
			
			if let (nextExpression, newState3) = state.getExpression() {
				return (.binaryExp(expression, operatorCharacter, nextExpression), newState3)
			} else {
				return (.suffix(expression, operatorCharacter),  newState2)
			}
		} else {
			return (expression, state)
		}
	}
	
	func getExpressionOperator() -> (value : String, state : State)? {
		let state = ignoreWhitespace()
		
		for op in ["+", "-", "*", "/", "%", "<<", ">>", "|", "&"] {
			if let newState = state.match(string: op) {
				return (op, newState)
			}
		}
		
		return nil
	}
}