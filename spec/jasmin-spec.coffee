TextEditor = null
buildTextEditor = (params) ->
  if atom.workspace.buildTextEditor?
    atom.workspace.buildTextEditor(params)
  else
    TextEditor ?= require('atom').TextEditor
    new TextEditor(params)

describe "Language-Jasmin", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-jasmin')

  describe "Jasmin", ->
    beforeEach ->
      grammar = atom.grammars.grammarForScopeName('source.mil')

    it "parses the grammar", ->
      expect(grammar).toBeTruthy()
      expect(grammar.scopeName).toBe 'source.mil'

    it "tokenizes punctuation", ->
      {tokens} = grammar.tokenizeLine 'hi;'
      expect(tokens[1]).toEqual value: ';', scopes: ['source.mil', 'punctuation.terminator.statement.mil']

      {tokens} = grammar.tokenizeLine 'a[b]'
      expect(tokens[1]).toEqual value: '[', scopes: ['source.mil', 'punctuation.definition.begin.bracket.square.mil']
      expect(tokens[3]).toEqual value: ']', scopes: ['source.mil', 'punctuation.definition.end.bracket.square.mil']

      {tokens} = grammar.tokenizeLine 'a, b'
      expect(tokens[1]).toEqual value: ',', scopes: ['source.mil', 'punctuation.separator.delimiter.mil']

    it "tokenizes functions", ->
      lines = grammar.tokenizeLines '''
        int something(int param) {
          return 0;
        }
      '''
      expect(lines[0][0]).toEqual value: 'int', scopes: ['source.mil', 'storage.type.mil']
      expect(lines[0][2]).toEqual value: 'something', scopes: ['source.mil', 'meta.function.mil', 'entity.name.function.mil']
      expect(lines[0][3]).toEqual value: '(', scopes: ['source.mil', 'meta.function.mil', 'punctuation.section.parameters.begin.bracket.round.mil']
      expect(lines[0][4]).toEqual value: 'int', scopes: ['source.mil', 'meta.function.mil', 'storage.type.mil']
      expect(lines[0][6]).toEqual value: ')', scopes: ['source.mil', 'meta.function.mil', 'punctuation.section.parameters.end.bracket.round.mil']
      expect(lines[0][8]).toEqual value: '{', scopes: ['source.mil', 'meta.block.mil', 'punctuation.section.block.begin.bracket.curly.mil']
      expect(lines[1][1]).toEqual value: 'return', scopes: ['source.mil', 'meta.block.mil', 'keyword.control.mil']
      expect(lines[1][3]).toEqual value: '0', scopes: ['source.mil', 'meta.block.mil', 'constant.numeric.mil']
      expect(lines[2][0]).toEqual value: '}', scopes: ['source.mil', 'meta.block.mil', 'punctuation.section.block.end.bracket.curly.mil']

    it "tokenizes varargs ellipses", ->
      {tokens} = grammar.tokenizeLine 'void function(...);'
      expect(tokens[0]).toEqual value: 'void', scopes: ['source.mil', 'storage.type.mil']
      expect(tokens[2]).toEqual value: 'function', scopes: ['source.mil', 'meta.function.mil', 'entity.name.function.mil']
      expect(tokens[3]).toEqual value: '(', scopes: ['source.mil', 'meta.function.mil', 'punctuation.section.parameters.begin.bracket.round.mil']
      expect(tokens[4]).toEqual value: '...', scopes: ['source.mil', 'meta.function.mil', 'punctuation.vararg-ellipses.mil']
      expect(tokens[5]).toEqual value: ')', scopes: ['source.mil', 'meta.function.mil', 'punctuation.section.parameters.end.bracket.round.mil']

    it "tokenizes various _t types", ->
      {tokens} = grammar.tokenizeLine 'size_t var;'
      expect(tokens[0]).toEqual value: 'size_t', scopes: ['source.mil', 'support.type.sys-types.mil']

      {tokens} = grammar.tokenizeLine 'pthread_t var;'
      expect(tokens[0]).toEqual value: 'pthread_t', scopes: ['source.mil', 'support.type.pthread.mil']

      {tokens} = grammar.tokenizeLine 'int32_t var;'
      expect(tokens[0]).toEqual value: 'int32_t', scopes: ['source.mil', 'support.type.stdint.mil']

      {tokens} = grammar.tokenizeLine 'myType_t var;'
      expect(tokens[0]).toEqual value: 'myType_t', scopes: ['source.mil', 'support.type.posix-reserved.mil']

    it "tokenizes 'line continuation' character", ->
      {tokens} = grammar.tokenizeLine 'ma' + '\\' + '\n' + 'in(){};'
      expect(tokens[0]).toEqual value: 'ma', scopes: ['source.mil']
      expect(tokens[1]).toEqual value: '\\', scopes: ['source.mil', 'constant.character.escape.line-continuation.mil']
      expect(tokens[3]).toEqual value: 'in', scopes: ['source.mil', 'meta.function.mil', 'entity.name.function.mil']

    describe "strings", ->
      it "tokenizes them", ->
        delimsByScope =
          'string.quoted.double.mil': '"'
          'string.quoted.single.mil': '\''

        for scope, delim of delimsByScope
          {tokens} = grammar.tokenizeLine delim + 'a' + delim
          expect(tokens[0]).toEqual value: delim, scopes: ['source.mil', scope, 'punctuation.definition.string.begin.mil']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.mil', scope]
          expect(tokens[2]).toEqual value: delim, scopes: ['source.mil', scope, 'punctuation.definition.string.end.mil']

          {tokens} = grammar.tokenizeLine delim + 'a' + '\\' + '\n' + 'b' + delim
          expect(tokens[0]).toEqual value: delim, scopes: ['source.mil', scope, 'punctuation.definition.string.begin.mil']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.mil', scope]
          expect(tokens[2]).toEqual value: '\\', scopes: ['source.mil', scope, 'constant.character.escape.line-continuation.mil']
          expect(tokens[4]).toEqual value: 'b', scopes: ['source.mil', scope]
          expect(tokens[5]).toEqual value: delim, scopes: ['source.mil', scope, 'punctuation.definition.string.end.mil']

        {tokens} = grammar.tokenizeLine '"%d"'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.mil', 'string.quoted.double.mil', 'punctuation.definition.string.begin.mil']
        expect(tokens[1]).toEqual value: '%d', scopes: ['source.mil', 'string.quoted.double.mil', 'constant.other.placeholder.mil']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.mil', 'string.quoted.double.mil', 'punctuation.definition.string.end.mil']

        {tokens} = grammar.tokenizeLine '"%"'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.mil', 'string.quoted.double.mil', 'punctuation.definition.string.begin.mil']
        expect(tokens[1]).toEqual value: '%', scopes: ['source.mil', 'string.quoted.double.mil', 'invalid.illegal.placeholder.mil']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.mil', 'string.quoted.double.mil', 'punctuation.definition.string.end.mil']

        {tokens} = grammar.tokenizeLine '"%" PRId32'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.mil', 'string.quoted.double.mil', 'punctuation.definition.string.begin.mil']
        expect(tokens[1]).toEqual value: '%', scopes: ['source.mil', 'string.quoted.double.mil']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.mil', 'string.quoted.double.mil', 'punctuation.definition.string.end.mil']

        {tokens} = grammar.tokenizeLine '"%" SCNd32'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.mil', 'string.quoted.double.mil', 'punctuation.definition.string.begin.mil']
        expect(tokens[1]).toEqual value: '%', scopes: ['source.mil', 'string.quoted.double.mil']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.mil', 'string.quoted.double.mil', 'punctuation.definition.string.end.mil']

    describe "comments", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine '/**/'
        expect(tokens[0]).toEqual value: '/*', scopes: ['source.mil', 'comment.block.mil', 'punctuation.definition.comment.begin.mil']
        expect(tokens[1]).toEqual value: '*/', scopes: ['source.mil', 'comment.block.mil', 'punctuation.definition.comment.end.mil']

        {tokens} = grammar.tokenizeLine '/* foo */'
        expect(tokens[0]).toEqual value: '/*', scopes: ['source.mil', 'comment.block.mil', 'punctuation.definition.comment.begin.mil']
        expect(tokens[1]).toEqual value: ' foo ', scopes: ['source.mil', 'comment.block.mil']
        expect(tokens[2]).toEqual value: '*/', scopes: ['source.mil', 'comment.block.mil', 'punctuation.definition.comment.end.mil']

        {tokens} = grammar.tokenizeLine '*/*'
        expect(tokens[0]).toEqual value: '*/*', scopes: ['source.mil', 'invalid.illegal.stray-comment-end.mil']

    describe "preprocessor directives", ->
      it "tokenizes '#line'", ->
        {tokens} = grammar.tokenizeLine '#line 151 "copy.c"'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.line.mil', 'punctuation.definition.directive.mil']
        expect(tokens[1]).toEqual value: 'line', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.line.mil']
        expect(tokens[3]).toEqual value: '151', scopes: ['source.mil', 'meta.preprocessor.mil', 'constant.numeric.mil']
        expect(tokens[5]).toEqual value: '"', scopes: ['source.mil', 'meta.preprocessor.mil', 'string.quoted.double.mil', 'punctuation.definition.string.begin.mil']
        expect(tokens[6]).toEqual value: 'copy.mil', scopes: ['source.mil', 'meta.preprocessor.mil', 'string.quoted.double.mil']
        expect(tokens[7]).toEqual value: '"', scopes: ['source.mil', 'meta.preprocessor.mil', 'string.quoted.double.mil', 'punctuation.definition.string.end.mil']

      it "tokenizes '#undef'", ->
        {tokens} = grammar.tokenizeLine '#undef FOO'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.undef.mil', 'punctuation.definition.directive.mil']
        expect(tokens[1]).toEqual value: 'undef', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.undef.mil']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.mil']
        expect(tokens[3]).toEqual value: 'FOO', scopes: ['source.mil', 'meta.preprocessor.mil', 'entity.name.function.preprocessor.mil']

      it "tokenizes '#pragma'", ->
        {tokens} = grammar.tokenizeLine '#pragma once'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.pragma.mil', 'keyword.control.directive.pragma.mil', 'punctuation.definition.directive.mil']
        expect(tokens[1]).toEqual value: 'pragma', scopes: ['source.mil', 'meta.preprocessor.pragma.mil', 'keyword.control.directive.pragma.mil']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.pragma.mil']
        expect(tokens[3]).toEqual value: 'once', scopes: ['source.mil', 'meta.preprocessor.pragma.mil', 'entity.other.attribute-name.pragma.preprocessor.mil']

        {tokens} = grammar.tokenizeLine '#pragma clang diagnostic ignored "-Wunused-variable"'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.pragma.mil', 'keyword.control.directive.pragma.mil', 'punctuation.definition.directive.mil']
        expect(tokens[1]).toEqual value: 'pragma', scopes: ['source.mil', 'meta.preprocessor.pragma.mil', 'keyword.control.directive.pragma.mil']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.pragma.mil']
        expect(tokens[3]).toEqual value: 'clang', scopes: ['source.mil', 'meta.preprocessor.pragma.mil', 'entity.other.attribute-name.pragma.preprocessor.mil']
        expect(tokens[5]).toEqual value: 'diagnostic', scopes: ['source.mil', 'meta.preprocessor.pragma.mil', 'entity.other.attribute-name.pragma.preprocessor.mil']
        expect(tokens[7]).toEqual value: 'ignored', scopes: ['source.mil', 'meta.preprocessor.pragma.mil', 'entity.other.attribute-name.pragma.preprocessor.mil']
        expect(tokens[10]).toEqual value: '-Wunused-variable', scopes: ['source.mil', 'meta.preprocessor.pragma.mil', 'string.quoted.double.mil']

        {tokens} = grammar.tokenizeLine '#pragma mark – Initialization'
        expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.section', 'meta.preprocessor.pragma.mil', 'keyword.control.directive.pragma.pragma-mark.mil',  'punctuation.definition.directive.mil']
        expect(tokens[1]).toEqual value: 'pragma mark', scopes: ['source.mil', 'meta.section',  'meta.preprocessor.pragma.mil', 'keyword.control.directive.pragma.pragma-mark.mil']
        expect(tokens[3]).toEqual value: '– Initialization', scopes: ['source.mil', 'meta.section',  'meta.preprocessor.pragma.mil', 'entity.name.tag.pragma-mark.mil']

      describe "define", ->
        it "tokenizes '#define [identifier name]'", ->
          {tokens} = grammar.tokenizeLine '#define _FILE_NAME_H_'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil', 'punctuation.definition.directive.mil']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil']
          expect(tokens[3]).toEqual value: '_FILE_NAME_H_', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'entity.name.function.preprocessor.mil']

        it "tokenizes '#define [identifier name] [value]'", ->
          {tokens} = grammar.tokenizeLine '#define WIDTH 80'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil', 'punctuation.definition.directive.mil']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil']
          expect(tokens[3]).toEqual value: 'WIDTH', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'entity.name.function.preprocessor.mil']
          expect(tokens[5]).toEqual value: '80', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'constant.numeric.mil']

          {tokens} = grammar.tokenizeLine '#define ABC XYZ(1)'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil', 'punctuation.definition.directive.mil']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil']
          expect(tokens[3]).toEqual value: 'ABC', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'entity.name.function.preprocessor.mil']
          expect(tokens[4]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.macro.mil']
          expect(tokens[5]).toEqual value: 'XYZ', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.function.mil', 'entity.name.function.mil']
          expect(tokens[6]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.function.mil', 'punctuation.section.arguments.begin.bracket.round.mil']
          expect(tokens[7]).toEqual value: '1', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.function.mil', 'constant.numeric.mil']
          expect(tokens[8]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.function.mil', 'punctuation.section.arguments.end.bracket.round.mil']

          {tokens} = grammar.tokenizeLine '#define PI_PLUS_ONE (3.14 + 1)'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil', 'punctuation.definition.directive.mil']
          expect(tokens[1]).toEqual value: 'define', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil']
          expect(tokens[3]).toEqual value: 'PI_PLUS_ONE', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'entity.name.function.preprocessor.mil']
          expect(tokens[4]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.macro.mil']
          expect(tokens[5]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.section.parens.begin.bracket.round.mil']
          expect(tokens[6]).toEqual value: '3.14', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'constant.numeric.mil']
          expect(tokens[8]).toEqual value: '+', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.operator.mil']
          expect(tokens[10]).toEqual value: '1', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'constant.numeric.mil']
          expect(tokens[11]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.section.parens.end.bracket.round.mil']

        describe "macros", ->
          it "tokenizes them", ->
            {tokens} = grammar.tokenizeLine '#define INCREMENT(x) x++'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil', 'punctuation.definition.directive.mil']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil']
            expect(tokens[3]).toEqual value: 'INCREMENT', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'entity.name.function.preprocessor.mil']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.definition.parameters.begin.mil']
            expect(tokens[5]).toEqual value: 'x', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'variable.parameter.preprocessor.mil']
            expect(tokens[6]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.definition.parameters.end.mil']
            expect(tokens[7]).toEqual value: ' x', scopes: ['source.mil', 'meta.preprocessor.macro.mil']
            expect(tokens[8]).toEqual value: '++', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.operator.increment.mil']

            {tokens} = grammar.tokenizeLine '#define MULT(x, y) (x) * (y)'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil', 'punctuation.definition.directive.mil']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil']
            expect(tokens[3]).toEqual value: 'MULT', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'entity.name.function.preprocessor.mil']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.definition.parameters.begin.mil']
            expect(tokens[5]).toEqual value: 'x', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'variable.parameter.preprocessor.mil']
            expect(tokens[6]).toEqual value: ',', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'variable.parameter.preprocessor.mil', 'punctuation.separator.parameters.mil']
            expect(tokens[7]).toEqual value: ' y', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'variable.parameter.preprocessor.mil']
            expect(tokens[8]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.definition.parameters.end.mil']
            expect(tokens[9]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.macro.mil']
            expect(tokens[10]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.section.parens.begin.bracket.round.mil']
            expect(tokens[11]).toEqual value: 'x', scopes: ['source.mil', 'meta.preprocessor.macro.mil']
            expect(tokens[12]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.section.parens.end.bracket.round.mil']
            expect(tokens[13]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.macro.mil']
            expect(tokens[14]).toEqual value: '*', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.operator.mil']
            expect(tokens[15]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.macro.mil']
            expect(tokens[16]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.section.parens.begin.bracket.round.mil']
            expect(tokens[17]).toEqual value: 'y', scopes: ['source.mil', 'meta.preprocessor.macro.mil']
            expect(tokens[18]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.section.parens.end.bracket.round.mil']

            {tokens} = grammar.tokenizeLine '#define SWAP(a, b)  do { a ^= b; b ^= a; a ^= b; } while ( 0 )'
            expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil', 'punctuation.definition.directive.mil']
            expect(tokens[1]).toEqual value: 'define', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil']
            expect(tokens[3]).toEqual value: 'SWAP', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'entity.name.function.preprocessor.mil']
            expect(tokens[4]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.definition.parameters.begin.mil']
            expect(tokens[5]).toEqual value: 'a', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'variable.parameter.preprocessor.mil']
            expect(tokens[6]).toEqual value: ',', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'variable.parameter.preprocessor.mil', 'punctuation.separator.parameters.mil']
            expect(tokens[7]).toEqual value: ' b', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'variable.parameter.preprocessor.mil']
            expect(tokens[8]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.definition.parameters.end.mil']
            expect(tokens[10]).toEqual value: 'do', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.mil']
            expect(tokens[12]).toEqual value: '{', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.block.begin.bracket.curly.mil']
            expect(tokens[13]).toEqual value: ' a ', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil']
            expect(tokens[14]).toEqual value: '^=', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'keyword.operator.assignment.compound.bitwise.mil']
            expect(tokens[15]).toEqual value: ' b', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil']
            expect(tokens[16]).toEqual value: ';', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.terminator.statement.mil']
            expect(tokens[17]).toEqual value: ' b ', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil']
            expect(tokens[18]).toEqual value: '^=', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'keyword.operator.assignment.compound.bitwise.mil']
            expect(tokens[19]).toEqual value: ' a', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil']
            expect(tokens[20]).toEqual value: ';', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.terminator.statement.mil']
            expect(tokens[21]).toEqual value: ' a ', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil']
            expect(tokens[22]).toEqual value: '^=', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'keyword.operator.assignment.compound.bitwise.mil']
            expect(tokens[23]).toEqual value: ' b', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil']
            expect(tokens[24]).toEqual value: ';', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.terminator.statement.mil']
            expect(tokens[25]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil']
            expect(tokens[26]).toEqual value: '}', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.block.end.bracket.curly.mil']
            expect(tokens[28]).toEqual value: 'while', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.mil']
            expect(tokens[29]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.macro.mil']
            expect(tokens[30]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.section.parens.begin.bracket.round.mil']
            expect(tokens[32]).toEqual value: '0', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'constant.numeric.mil']
            expect(tokens[34]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.section.parens.end.bracket.round.mil']

          it "tokenizes multiline macros", ->
            lines = grammar.tokenizeLines '''
              #define max(a,b) (a>b)? \\
                                a:b
            '''
            expect(lines[0][17]).toEqual value: '\\', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'constant.character.escape.line-continuation.mil']
            expect(lines[1][0]).toEqual value: '                  a', scopes: ['source.mil', 'meta.preprocessor.macro.mil']

            lines = grammar.tokenizeLines '''
              #define SWAP(a, b)  { \\
                a ^= b; \\
                b ^= a; \\
                a ^= b; \\
              }
            '''
            expect(lines[0][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil', 'punctuation.definition.directive.mil']
            expect(lines[0][1]).toEqual value: 'define', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil']
            expect(lines[0][3]).toEqual value: 'SWAP', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'entity.name.function.preprocessor.mil']
            expect(lines[0][4]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.definition.parameters.begin.mil']
            expect(lines[0][5]).toEqual value: 'a', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'variable.parameter.preprocessor.mil']
            expect(lines[0][6]).toEqual value: ',', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'variable.parameter.preprocessor.mil', 'punctuation.separator.parameters.mil']
            expect(lines[0][7]).toEqual value: ' b', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'variable.parameter.preprocessor.mil']
            expect(lines[0][8]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.definition.parameters.end.mil']
            expect(lines[0][10]).toEqual value: '{', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.block.begin.bracket.curly.mil']
            expect(lines[0][12]).toEqual value: '\\', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'constant.character.escape.line-continuation.mil']
            expect(lines[1][1]).toEqual value: '^=', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'keyword.operator.assignment.compound.bitwise.mil']
            expect(lines[1][5]).toEqual value: '\\', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'constant.character.escape.line-continuation.mil']
            expect(lines[2][1]).toEqual value: '^=', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'keyword.operator.assignment.compound.bitwise.mil']
            expect(lines[2][5]).toEqual value: '\\', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'constant.character.escape.line-continuation.mil']
            expect(lines[3][1]).toEqual value: '^=', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'keyword.operator.assignment.compound.bitwise.mil']
            expect(lines[3][5]).toEqual value: '\\', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'constant.character.escape.line-continuation.mil']
            expect(lines[4][0]).toEqual value: '}', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.block.end.bracket.curly.mil']

          it "tokenizes complex definitions", ->
            lines = grammar.tokenizeLines '''
              #define MakeHook(name) struct HOOK name = {{false, 0L}, \\
              ((HOOKF)(*HookEnt)), ID("hook")}
            '''
            expect(lines[0][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil', 'punctuation.definition.directive.mil']
            expect(lines[0][1]).toEqual value: 'define', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil']
            expect(lines[0][3]).toEqual value: 'MakeHook', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'entity.name.function.preprocessor.mil']
            expect(lines[0][4]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.definition.parameters.begin.mil']
            expect(lines[0][5]).toEqual value: 'name', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'variable.parameter.preprocessor.mil']
            expect(lines[0][6]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'punctuation.definition.parameters.end.mil']
            expect(lines[0][8]).toEqual value: 'struct', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'storage.type.mil']
            expect(lines[0][10]).toEqual value: '=', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.operator.assignment.mil']
            expect(lines[0][12]).toEqual value: '{', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.block.begin.bracket.curly.mil']
            expect(lines[0][13]).toEqual value: '{', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.block.begin.bracket.curly.mil']
            expect(lines[0][14]).toEqual value: 'false', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'constant.language.mil']
            expect(lines[0][15]).toEqual value: ',', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.separator.delimiter.mil']
            expect(lines[0][17]).toEqual value: '0L', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'constant.numeric.mil']
            expect(lines[0][18]).toEqual value: '}', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.block.end.bracket.curly.mil']
            expect(lines[0][19]).toEqual value: ',', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.separator.delimiter.mil']
            expect(lines[0][21]).toEqual value: '\\', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'constant.character.escape.line-continuation.mil']
            expect(lines[1][0]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.parens.begin.bracket.round.mil']
            expect(lines[1][1]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.parens.begin.bracket.round.mil']
            expect(lines[1][3]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.parens.end.bracket.round.mil']
            expect(lines[1][4]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.parens.begin.bracket.round.mil']
            expect(lines[1][5]).toEqual value: '*', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'keyword.operator.mil']
            expect(lines[1][7]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.parens.end.bracket.round.mil']
            expect(lines[1][8]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.parens.end.bracket.round.mil']
            expect(lines[1][9]).toEqual value: ',', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.separator.delimiter.mil']
            expect(lines[1][11]).toEqual value: 'ID', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'meta.function.mil', 'entity.name.function.mil']
            expect(lines[1][12]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'meta.function.mil', 'punctuation.section.arguments.begin.bracket.round.mil']
            expect(lines[1][13]).toEqual value: '"', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'meta.function.mil', 'string.quoted.double.mil', "punctuation.definition.string.begin.c"]
            expect(lines[1][14]).toEqual value: 'hook', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'meta.function.mil', 'string.quoted.double.mil']
            expect(lines[1][15]).toEqual value: '"', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'meta.function.mil', 'string.quoted.double.mil', "punctuation.definition.string.end.c"]
            expect(lines[1][16]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'meta.function.mil', 'punctuation.section.arguments.end.bracket.round.mil']
            expect(lines[1][17]).toEqual value: '}', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'meta.block.mil', 'punctuation.section.block.end.bracket.curly.mil']

      describe "includes", ->
        it "tokenizes '#include'", ->
          {tokens} = grammar.tokenizeLine '#include <stdio.h>'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil', 'punctuation.definition.directive.mil']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil']
          expect(tokens[3]).toEqual value: '<', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil', 'punctuation.definition.string.begin.mil']
          expect(tokens[4]).toEqual value: 'stdio.h', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil']
          expect(tokens[5]).toEqual value: '>', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil', 'punctuation.definition.string.end.mil']

          {tokens} = grammar.tokenizeLine '#include<stdio.h>'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil', 'punctuation.definition.directive.mil']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil']
          expect(tokens[2]).toEqual value: '<', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil', 'punctuation.definition.string.begin.mil']
          expect(tokens[3]).toEqual value: 'stdio.h', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil']
          expect(tokens[4]).toEqual value: '>', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil', 'punctuation.definition.string.end.mil']

          {tokens} = grammar.tokenizeLine '#include_<stdio.h>'
          expect(tokens[0]).toEqual value: '#include_', scopes: ['source.mil']

          {tokens} = grammar.tokenizeLine '#include "file"'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil', 'punctuation.definition.directive.mil']
          expect(tokens[1]).toEqual value: 'include', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil']
          expect(tokens[3]).toEqual value: '"', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil', 'punctuation.definition.string.begin.mil']
          expect(tokens[4]).toEqual value: 'file', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil']
          expect(tokens[5]).toEqual value: '"', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil', 'punctuation.definition.string.end.mil']

        it "tokenizes '#import'", ->
          {tokens} = grammar.tokenizeLine '#import "file"'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.import.mil', 'punctuation.definition.directive.mil']
          expect(tokens[1]).toEqual value: 'import', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.import.mil']
          expect(tokens[3]).toEqual value: '"', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil', 'punctuation.definition.string.begin.mil']
          expect(tokens[4]).toEqual value: 'file', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil']
          expect(tokens[5]).toEqual value: '"', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil', 'punctuation.definition.string.end.mil']

        it "tokenizes '#include_next'", ->
          {tokens} = grammar.tokenizeLine '#include_next "next.h"'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include_next.mil', 'punctuation.definition.directive.mil']
          expect(tokens[1]).toEqual value: 'include_next', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include_next.mil']
          expect(tokens[3]).toEqual value: '"', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil', 'punctuation.definition.string.begin.mil']
          expect(tokens[4]).toEqual value: 'next.h', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil']
          expect(tokens[5]).toEqual value: '"', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil', 'punctuation.definition.string.end.mil']

      describe "diagnostics", ->
        it "tokenizes '#error'", ->
          {tokens} = grammar.tokenizeLine '#error "C++ compiler required."'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.diagnostic.mil', 'keyword.control.directive.diagnostic.error.mil', 'punctuation.definition.directive.mil']
          expect(tokens[1]).toEqual value: 'error', scopes: ['source.mil', 'meta.preprocessor.diagnostic.mil', 'keyword.control.directive.diagnostic.error.mil']
          expect(tokens[4]).toEqual value: 'C++ compiler required.', scopes: ['source.mil', 'meta.preprocessor.diagnostic.mil', 'string.quoted.double.mil']

        it "tokenizes '#warning'", ->
          {tokens} = grammar.tokenizeLine '#warning "This is a warning."'
          expect(tokens[0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.diagnostic.mil', 'keyword.control.directive.diagnostic.warning.mil', 'punctuation.definition.directive.mil']
          expect(tokens[1]).toEqual value: 'warning', scopes: ['source.mil', 'meta.preprocessor.diagnostic.mil', 'keyword.control.directive.diagnostic.warning.mil']
          expect(tokens[4]).toEqual value: 'This is a warning.', scopes: ['source.mil', 'meta.preprocessor.diagnostic.mil', 'string.quoted.double.mil']

      describe "conditionals", ->
        it "tokenizes if-elif-else preprocessor blocks", ->
          lines = grammar.tokenizeLines '''
            #if defined(CREDIT)
                credit();
            #elif defined(DEBIT)
                debit();
            #else
                printerror();
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[0][3]).toEqual value: 'defined', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[0][5]).toEqual value: 'CREDIT', scopes: ['source.mil', 'meta.preprocessor.mil', 'entity.name.function.preprocessor.mil']
          expect(lines[1][1]).toEqual value: 'credit', scopes: ['source.mil', 'meta.function.mil', 'entity.name.function.mil']
          expect(lines[1][2]).toEqual value: '(', scopes: ['source.mil', 'meta.function.mil', 'punctuation.section.parameters.begin.bracket.round.mil']
          expect(lines[1][3]).toEqual value: ')', scopes: ['source.mil', 'meta.function.mil', 'punctuation.section.parameters.end.bracket.round.mil']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[2][1]).toEqual value: 'elif', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[2][3]).toEqual value: 'defined', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[2][5]).toEqual value: 'DEBIT', scopes: ['source.mil', 'meta.preprocessor.mil', 'entity.name.function.preprocessor.mil']
          expect(lines[3][1]).toEqual value: 'debit', scopes: ['source.mil', 'meta.function.mil', 'entity.name.function.mil']
          expect(lines[3][2]).toEqual value: '(', scopes: ['source.mil', 'meta.function.mil', 'punctuation.section.parameters.begin.bracket.round.mil']
          expect(lines[3][3]).toEqual value: ')', scopes: ['source.mil', 'meta.function.mil', 'punctuation.section.parameters.end.bracket.round.mil']
          expect(lines[4][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[4][1]).toEqual value: 'else', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[5][1]).toEqual value: 'printerror', scopes: ['source.mil', 'meta.function.mil', 'entity.name.function.mil']
          expect(lines[5][2]).toEqual value: '(', scopes: ['source.mil', 'meta.function.mil', 'punctuation.section.parameters.begin.bracket.round.mil']
          expect(lines[5][3]).toEqual value: ')', scopes: ['source.mil', 'meta.function.mil', 'punctuation.section.parameters.end.bracket.round.mil']
          expect(lines[6][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[6][1]).toEqual value: 'endif', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']

        it "tokenizes if-true-else blocks", ->
          lines = grammar.tokenizeLines '''
            #if 1
            int something() {
              #if 1
                return 1;
              #else
                return 0;
              #endif
            }
            #else
            int something() {
              return 0;
            }
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[0][3]).toEqual value: '1', scopes: ['source.mil', 'meta.preprocessor.mil', 'constant.numeric.mil']
          expect(lines[1][0]).toEqual value: 'int', scopes: ['source.mil', 'storage.type.mil']
          expect(lines[1][2]).toEqual value: 'something', scopes: ['source.mil', 'meta.function.mil', 'entity.name.function.mil']
          expect(lines[2][1]).toEqual value: '#', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[2][2]).toEqual value: 'if', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[2][4]).toEqual value: '1', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'constant.numeric.mil']
          expect(lines[3][1]).toEqual value: 'return', scopes: ['source.mil', 'meta.block.mil', 'keyword.control.mil']
          expect(lines[3][3]).toEqual value: '1', scopes: ['source.mil', 'meta.block.mil', 'constant.numeric.mil']
          expect(lines[4][1]).toEqual value: '#', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[4][2]).toEqual value: 'else', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[5][0]).toEqual value: '    return 0;', scopes: ['source.mil', 'meta.block.mil', 'comment.block.preprocessor.else-branch.in-block.mil']
          expect(lines[6][1]).toEqual value: '#', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[6][2]).toEqual value: 'endif', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[8][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[8][1]).toEqual value: 'else', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[9][0]).toEqual value: 'int something() {', scopes: ['source.mil', 'comment.block.preprocessor.else-branch.mil']
          expect(lines[12][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[12][1]).toEqual value: 'endif', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']

        it "tokenizes if-false-else blocks", ->
          lines = grammar.tokenizeLines '''
            int something() {
              #if 0
                return 1;
              #else
                return 0;
              #endif
            }
          '''
          expect(lines[0][0]).toEqual value: 'int', scopes: ['source.mil', 'storage.type.mil']
          expect(lines[0][2]).toEqual value: 'something', scopes: ['source.mil', 'meta.function.mil', 'entity.name.function.mil']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[1][2]).toEqual value: 'if', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[1][4]).toEqual value: '0', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'constant.numeric.mil']
          expect(lines[2][0]).toEqual value: '    return 1;', scopes: ['source.mil', 'meta.block.mil', 'comment.block.preprocessor.if-branch.in-block.mil']
          expect(lines[3][1]).toEqual value: '#', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[3][2]).toEqual value: 'else', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[4][1]).toEqual value: 'return', scopes: ['source.mil', 'meta.block.mil', 'keyword.control.mil']
          expect(lines[4][3]).toEqual value: '0', scopes: ['source.mil', 'meta.block.mil', 'constant.numeric.mil']
          expect(lines[5][1]).toEqual value: '#', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[5][2]).toEqual value: 'endif', scopes: ['source.mil', 'meta.block.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']

          lines = grammar.tokenizeLines '''
            #if 0
              something();
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[0][1]).toEqual value: 'if', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[0][3]).toEqual value: '0', scopes: ['source.mil', 'meta.preprocessor.mil', 'constant.numeric.mil']
          expect(lines[1][0]).toEqual value: '  something();', scopes: ['source.mil', 'comment.block.preprocessor.if-branch.mil']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[2][1]).toEqual value: 'endif', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']

        it "tokenizes ifdef-elif blocks", ->
          lines = grammar.tokenizeLines '''
            #ifdef __unix__ /* is defined by compilers targeting Unix systems */
              # include <unistd.h>
            #elif defined _WIN32 /* is defined by compilers targeting Windows systems */
              # include <windows.h>
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[0][1]).toEqual value: 'ifdef', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[0][3]).toEqual value: '__unix__', scopes: ['source.mil', 'meta.preprocessor.mil', 'entity.name.function.preprocessor.mil']
          expect(lines[0][5]).toEqual value: '/*', scopes: ['source.mil', 'comment.block.mil', 'punctuation.definition.comment.begin.mil']
          expect(lines[0][6]).toEqual value: ' is defined by compilers targeting Unix systems ', scopes: ['source.mil', 'comment.block.mil']
          expect(lines[0][7]).toEqual value: '*/', scopes: ['source.mil', 'comment.block.mil', 'punctuation.definition.comment.end.mil']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil', 'punctuation.definition.directive.mil']
          expect(lines[1][2]).toEqual value: ' include', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil']
          expect(lines[1][4]).toEqual value: '<', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil', 'punctuation.definition.string.begin.mil']
          expect(lines[1][5]).toEqual value: 'unistd.h', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil']
          expect(lines[1][6]).toEqual value: '>', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil', 'punctuation.definition.string.end.mil']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[2][1]).toEqual value: 'elif', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[2][3]).toEqual value: 'defined', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[2][5]).toEqual value: '_WIN32', scopes: ['source.mil', 'meta.preprocessor.mil', 'entity.name.function.preprocessor.mil']
          expect(lines[2][7]).toEqual value: '/*', scopes: ['source.mil', 'comment.block.mil', 'punctuation.definition.comment.begin.mil']
          expect(lines[2][8]).toEqual value: ' is defined by compilers targeting Windows systems ', scopes: ['source.mil', 'comment.block.mil']
          expect(lines[2][9]).toEqual value: '*/', scopes: ['source.mil', 'comment.block.mil', 'punctuation.definition.comment.end.mil']
          expect(lines[3][1]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil', 'punctuation.definition.directive.mil']
          expect(lines[3][2]).toEqual value: ' include', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil']
          expect(lines[3][4]).toEqual value: '<', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil', 'punctuation.definition.string.begin.mil']
          expect(lines[3][5]).toEqual value: 'windows.h', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil']
          expect(lines[3][6]).toEqual value: '>', scopes: ['source.mil', 'meta.preprocessor.include.mil', 'string.quoted.other.lt-gt.include.mil', 'punctuation.definition.string.end.mil']
          expect(lines[4][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[4][1]).toEqual value: 'endif', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']

        it "tokenizes ifndef blocks", ->
          lines = grammar.tokenizeLines '''
            #ifndef _INCL_GUARD
              #define _INCL_GUARD
            #endif
          '''
          expect(lines[0][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[0][1]).toEqual value: 'ifndef', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[0][3]).toEqual value: '_INCL_GUARD', scopes: ['source.mil', 'meta.preprocessor.mil', 'entity.name.function.preprocessor.mil']
          expect(lines[1][1]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil', 'punctuation.definition.directive.mil']
          expect(lines[1][2]).toEqual value: 'define', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'keyword.control.directive.define.mil']
          expect(lines[1][4]).toEqual value: '_INCL_GUARD', scopes: ['source.mil', 'meta.preprocessor.macro.mil', 'entity.name.function.preprocessor.mil']
          expect(lines[2][0]).toEqual value: '#', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
          expect(lines[2][1]).toEqual value: 'endif', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']

        it "highlights stray elif, else and endif usages as invalid", ->
          lines = grammar.tokenizeLines '''
            #if defined SOMEMACRO
            #else
            #elif  //elif not permitted here
            #endif
            #else  //else without if
            #endif //endif without if
          '''
          expect(lines[2][0]).toEqual value: '#elif', scopes: ['source.mil', 'invalid.illegal.stray-elif.mil']
          expect(lines[4][0]).toEqual value: '#else', scopes: ['source.mil', 'invalid.illegal.stray-else.mil']
          expect(lines[5][0]).toEqual value: '#endif', scopes: ['source.mil', 'invalid.illegal.stray-endif.mil']

        it "highlights errorneous defined usage as invalid", ->
          {tokens} = grammar.tokenizeLine '#if defined == VALUE'
          expect(tokens[3]).toEqual value: 'defined', scopes: ['source.mil', 'meta.preprocessor.mil', 'invalid.illegal.macro-name.mil']

        it "tokenizes multi line conditional queries", ->
          lines = grammar.tokenizeLines '''
            #if !defined (MACRO_A) \\
             || !defined MACRO_C
              #define MACRO_A TRUE
            #elif MACRO_C == (5 + 4 -             /* multi line comment */  \\
                             SOMEMACRO(TRUE) * 8) // single line comment
            #endif
          '''
          expect(lines[0][2]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.mil']
          expect(lines[0][3]).toEqual value: '!', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.operator.logical.mil']
          expect(lines[0][7]).toEqual value: 'MACRO_A', scopes: ['source.mil', 'meta.preprocessor.mil', 'entity.name.function.preprocessor.mil']
          expect(lines[0][10]).toEqual value: '\\', scopes: ['source.mil', 'meta.preprocessor.mil', 'constant.character.escape.line-continuation.mil']
          expect(lines[1][1]).toEqual value: '||', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.operator.logical.mil']
          expect(lines[1][3]).toEqual value: '!', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.operator.logical.mil']
          expect(lines[1][4]).toEqual value: 'defined', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(lines[1][6]).toEqual value: 'MACRO_C', scopes: ['source.mil', 'meta.preprocessor.mil', 'entity.name.function.preprocessor.mil']
          expect(lines[3][2]).toEqual value: ' ', scopes: ['source.mil', 'meta.preprocessor.mil']
          expect(lines[3][3]).toEqual value: 'MACRO_C', scopes: ['source.mil', 'meta.preprocessor.mil', 'entity.name.function.preprocessor.mil']
          expect(lines[3][5]).toEqual value: '==', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.operator.comparison.mil']
          expect(lines[3][7]).toEqual value: '(', scopes: ['source.mil', 'meta.preprocessor.mil', 'punctuation.section.parens.begin.bracket.round.mil']
          expect(lines[3][8]).toEqual value: '5', scopes: ['source.mil', 'meta.preprocessor.mil', 'constant.numeric.mil']
          expect(lines[3][10]).toEqual value: '+', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.operator.mil']
          expect(lines[3][14]).toEqual value: '-', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.operator.mil']
          expect(lines[3][16]).toEqual value: '/*', scopes: ['source.mil', 'meta.preprocessor.mil', 'comment.block.mil', 'punctuation.definition.comment.begin.mil']
          expect(lines[3][17]).toEqual value: ' multi line comment ', scopes: ['source.mil', 'meta.preprocessor.mil', 'comment.block.mil']
          expect(lines[3][18]).toEqual value: '*/', scopes: ['source.mil', 'meta.preprocessor.mil', 'comment.block.mil', 'punctuation.definition.comment.end.mil']
          expect(lines[3][20]).toEqual value: '\\', scopes: ['source.mil', 'meta.preprocessor.mil', 'constant.character.escape.line-continuation.mil']
          expect(lines[4][1]).toEqual value: 'SOMEMACRO', scopes: ['source.mil', 'meta.preprocessor.mil', 'entity.name.function.preprocessor.mil']
          expect(lines[4][3]).toEqual value: 'TRUE', scopes: ['source.mil', 'meta.preprocessor.mil', 'constant.language.mil']
          expect(lines[4][6]).toEqual value: '*', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.operator.mil']
          expect(lines[4][9]).toEqual value: ')', scopes: ['source.mil', 'meta.preprocessor.mil', 'punctuation.section.parens.end.bracket.round.mil']
          expect(lines[4][11]).toEqual value: '//', scopes: ['source.mil', 'comment.line.double-slash.cpp', 'punctuation.definition.comment.cpp']
          expect(lines[4][12]).toEqual value: ' single line comment', scopes: ['source.mil', 'comment.line.double-slash.cpp']

        it "tokenizes ternary operator usage in preprocessor conditionals", ->
          {tokens} = grammar.tokenizeLine '#if defined (__GNU_LIBRARY__) ? defined (__USE_GNU) : !defined (__STRICT_ANSI__)'
          expect(tokens[9]).toEqual value: '?', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.operator.ternary.mil']
          expect(tokens[11]).toEqual value: 'defined', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
          expect(tokens[17]).toEqual value: ':', scopes: ['source.mil', 'meta.preprocessor.mil', 'keyword.operator.ternary.mil']

    describe "indentation", ->
      editor = null

      beforeEach ->
        editor = buildTextEditor()
        editor.setGrammar(grammar)

      expectPreservedIndentation = (text) ->
        editor.setText(text)
        editor.autoIndentBufferRows(0, editor.getLineCount() - 1)

        expectedLines = text.split('\n')
        actualLines = editor.getText().split('\n')
        for actualLine, i in actualLines
          expect([
            actualLine,
            editor.indentLevelForLine(actualLine)
          ]).toEqual([
            expectedLines[i],
            editor.indentLevelForLine(expectedLines[i])
          ])

      it "indents allman-style curly braces", ->
        expectPreservedIndentation '''
          if (a)
          {
            for (;;)
            {
              do
              {
                while (b)
                {
                  c();
                }
              }
              while (d)
            }
          }
        '''

      it "indents non-allman-style curly braces", ->
        expectPreservedIndentation '''
          if (a) {
            for (;;) {
              do {
                while (b) {
                  c();
                }
              } while (d)
            }
          }
        '''

      it "indents function arguments", ->
        expectPreservedIndentation '''
          a(
            b,
            c(
              d
            )
          );
        '''

      it "indents array and struct literals", ->
        expectPreservedIndentation '''
          some_t a[3] = {
            { .b = c },
            { .b = c, .d = {1, 2} },
          };
        '''

      it "tokenizes binary literal", ->
        {tokens} = grammar.tokenizeLine '0b101010'
        expect(tokens[0]).toEqual value: '0b101010', scopes: ['source.mil', 'constant.numeric.mil']

    describe "access", ->
      it "tokenizes the dot access operator", ->
        lines = grammar.tokenizeLines '''
          {
            a.
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.mil', 'meta.block.mil']
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.dot-access.mil']

        lines = grammar.tokenizeLines '''
          {
            a.b;
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.mil', 'meta.block.mil']
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.dot-access.mil']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.mil', 'meta.block.mil', 'variable.other.member.mil']

        lines = grammar.tokenizeLines '''
          {
            a.b()
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.mil', 'meta.block.mil']
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.dot-access.mil']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.mil', 'meta.block.mil', 'meta.function-call.mil', 'entity.name.function.mil']

        lines = grammar.tokenizeLines '''
          {
            a. b;
          }
        '''
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.dot-access.mil']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.mil', 'meta.block.mil', 'variable.other.member.mil']

        lines = grammar.tokenizeLines '''
          {
            a .b;
          }
        '''
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.dot-access.mil']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.mil', 'meta.block.mil', 'variable.other.member.mil']

        lines = grammar.tokenizeLines '''
          {
            a . b;
          }
        '''
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.dot-access.mil']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.mil', 'meta.block.mil', 'variable.other.member.mil']

      it "tokenizes the pointer access operator", ->
        lines = grammar.tokenizeLines '''
          {
            a->b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.pointer-access.mil']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.mil', 'meta.block.mil', 'variable.other.member.mil']

        lines = grammar.tokenizeLines '''
          {
            a->b()
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.mil', 'meta.block.mil']
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.pointer-access.mil']

        lines = grammar.tokenizeLines '''
          {
            a-> b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.pointer-access.mil']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.mil', 'meta.block.mil', 'variable.other.member.mil']

        lines = grammar.tokenizeLines '''
          {
            a ->b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.pointer-access.mil']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.mil', 'meta.block.mil', 'variable.other.member.mil']

        lines = grammar.tokenizeLines '''
          {
            a -> b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.pointer-access.mil']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.mil', 'meta.block.mil', 'variable.other.member.mil']

        lines = grammar.tokenizeLines '''
          {
            a->
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.mil', 'meta.block.mil']
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.mil', 'meta.block.mil', 'punctuation.separator.pointer-access.mil']

    describe "operators", ->
      it "tokenizes the sizeof operator", ->
        {tokens} = grammar.tokenizeLine('sizeof unary_expression')
        expect(tokens[0]).toEqual value: 'sizeof', scopes: ['source.mil', 'keyword.operator.sizeof.mil']
        expect(tokens[1]).toEqual value: ' unary_expression', scopes: ['source.mil']

        {tokens} = grammar.tokenizeLine('sizeof (int)')
        expect(tokens[0]).toEqual value: 'sizeof', scopes: ['source.mil', 'keyword.operator.sizeof.mil']
        expect(tokens[1]).toEqual value: ' ', scopes: ['source.mil']
        expect(tokens[2]).toEqual value: '(', scopes: ['source.mil', 'punctuation.section.parens.begin.bracket.round.mil']
        expect(tokens[3]).toEqual value: 'int', scopes: ['source.mil', 'storage.type.mil']
        expect(tokens[4]).toEqual value: ')', scopes: ['source.mil', 'punctuation.section.parens.end.bracket.round.mil']

        {tokens} = grammar.tokenizeLine('$sizeof')
        expect(tokens[1]).not.toEqual value: 'sizeof', scopes: ['source.mil', 'keyword.operator.sizeof.mil']

        {tokens} = grammar.tokenizeLine('sizeof$')
        expect(tokens[0]).not.toEqual value: 'sizeof', scopes: ['source.mil', 'keyword.operator.sizeof.mil']

        {tokens} = grammar.tokenizeLine('sizeof_')
        expect(tokens[0]).not.toEqual value: 'sizeof', scopes: ['source.mil', 'keyword.operator.sizeof.mil']

      it "tokenizes the increment operator", ->
        {tokens} = grammar.tokenizeLine('i++')
        expect(tokens[0]).toEqual value: 'i', scopes: ['source.mil']
        expect(tokens[1]).toEqual value: '++', scopes: ['source.mil', 'keyword.operator.increment.mil']

        {tokens} = grammar.tokenizeLine('++i')
        expect(tokens[0]).toEqual value: '++', scopes: ['source.mil', 'keyword.operator.increment.mil']
        expect(tokens[1]).toEqual value: 'i', scopes: ['source.mil']

      it "tokenizes the decrement operator", ->
        {tokens} = grammar.tokenizeLine('i--')
        expect(tokens[0]).toEqual value: 'i', scopes: ['source.mil']
        expect(tokens[1]).toEqual value: '--', scopes: ['source.mil', 'keyword.operator.decrement.mil']

        {tokens} = grammar.tokenizeLine('--i')
        expect(tokens[0]).toEqual value: '--', scopes: ['source.mil', 'keyword.operator.decrement.mil']
        expect(tokens[1]).toEqual value: 'i', scopes: ['source.mil']

      it "tokenizes logical operators", ->
        {tokens} = grammar.tokenizeLine('!a')
        expect(tokens[0]).toEqual value: '!', scopes: ['source.mil', 'keyword.operator.logical.mil']
        expect(tokens[1]).toEqual value: 'a', scopes: ['source.mil']

        operators = ['&&', '||']
        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.mil']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.mil', 'keyword.operator.logical.mil']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.mil']

      it "tokenizes comparison operators", ->
        operators = ['<=', '>=', '!=', '==', '<', '>' ]

        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.mil']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.mil', 'keyword.operator.comparison.mil']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.mil']

      it "tokenizes arithmetic operators", ->
        operators = ['+', '-', '*', '/', '%']

        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.mil']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.mil', 'keyword.operator.mil']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.mil']

      it "tokenizes ternary operators", ->
        {tokens} = grammar.tokenizeLine('a ? b : c')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.mil']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.mil', 'keyword.operator.ternary.mil']
        expect(tokens[2]).toEqual value: ' b ', scopes: ['source.mil']
        expect(tokens[3]).toEqual value: ':', scopes: ['source.mil', 'keyword.operator.ternary.mil']
        expect(tokens[4]).toEqual value: ' c', scopes: ['source.mil']

      it "tokenizes ternary operators with member access", ->
        {tokens} = grammar.tokenizeLine('a ? b.c : d')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.mil']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.mil', 'keyword.operator.ternary.mil']
        expect(tokens[2]).toEqual value: ' b', scopes: ['source.mil']
        expect(tokens[3]).toEqual value: '.', scopes: ['source.mil', 'punctuation.separator.dot-access.mil']
        expect(tokens[4]).toEqual value: 'c', scopes: ['source.mil', 'variable.other.member.mil']
        expect(tokens[5]).toEqual value: ' ', scopes: ['source.mil']
        expect(tokens[6]).toEqual value: ':', scopes: ['source.mil', 'keyword.operator.ternary.mil']
        expect(tokens[7]).toEqual value: ' d', scopes: ['source.mil']

      it "tokenizes ternary operators with pointer dereferencing", ->
        {tokens} = grammar.tokenizeLine('a ? b->c : d')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.mil']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.mil', 'keyword.operator.ternary.mil']
        expect(tokens[2]).toEqual value: ' b', scopes: ['source.mil']
        expect(tokens[3]).toEqual value: '->', scopes: ['source.mil', 'punctuation.separator.pointer-access.mil']
        expect(tokens[4]).toEqual value: 'c', scopes: ['source.mil', 'variable.other.member.mil']
        expect(tokens[5]).toEqual value: ' ', scopes: ['source.mil']
        expect(tokens[6]).toEqual value: ':', scopes: ['source.mil', 'keyword.operator.ternary.mil']
        expect(tokens[7]).toEqual value: ' d', scopes: ['source.mil']

      it "tokenizes ternary operators with function invocation", ->
        {tokens} = grammar.tokenizeLine('a ? f(b) : c')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.mil']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.mil', 'keyword.operator.ternary.mil']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.mil']
        expect(tokens[3]).toEqual value: 'f', scopes: ['source.mil', 'meta.function-call.mil', 'entity.name.function.mil']
        expect(tokens[4]).toEqual value: '(', scopes: ['source.mil', 'meta.function-call.mil', 'punctuation.section.arguments.begin.bracket.round.mil']
        expect(tokens[5]).toEqual value: 'b', scopes: ['source.mil', 'meta.function-call.mil']
        expect(tokens[6]).toEqual value: ')', scopes: ['source.mil', 'meta.function-call.mil', 'punctuation.section.arguments.end.bracket.round.mil']
        expect(tokens[7]).toEqual value: ' ', scopes: ['source.mil']
        expect(tokens[8]).toEqual value: ':', scopes: ['source.mil', 'keyword.operator.ternary.mil']
        expect(tokens[9]).toEqual value: ' c', scopes: ['source.mil']

      describe "bitwise", ->
        it "tokenizes bitwise 'not'", ->
          {tokens} = grammar.tokenizeLine('~a')
          expect(tokens[0]).toEqual value: '~', scopes: ['source.mil', 'keyword.operator.mil']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.mil']

        it "tokenizes shift operators", ->
          {tokens} = grammar.tokenizeLine('>>')
          expect(tokens[0]).toEqual value: '>>', scopes: ['source.mil', 'keyword.operator.bitwise.shift.mil']

          {tokens} = grammar.tokenizeLine('<<')
          expect(tokens[0]).toEqual value: '<<', scopes: ['source.mil', 'keyword.operator.bitwise.shift.mil']

        it "tokenizes them", ->
          operators = ['|', '^', '&']

          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.mil']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.mil', 'keyword.operator.mil']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.mil']

      describe "assignment", ->
        it "tokenizes the assignment operator", ->
          {tokens} = grammar.tokenizeLine('a = b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.mil']
          expect(tokens[1]).toEqual value: '=', scopes: ['source.mil', 'keyword.operator.assignment.mil']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.mil']

        it "tokenizes compound assignment operators", ->
          operators = ['+=', '-=', '*=', '/=', '%=']
          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.mil']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.mil', 'keyword.operator.assignment.compound.mil']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.mil']

        it "tokenizes bitwise compound operators", ->
          operators = ['<<=', '>>=', '&=', '^=', '|=']
          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.mil']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.mil', 'keyword.operator.assignment.compound.bitwise.mil']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.mil']

  describe "C++", ->
    beforeEach ->
      grammar = atom.grammars.grammarForScopeName('source.cpp')

    it "parses the grammar", ->
      expect(grammar).toBeTruthy()
      expect(grammar.scopeName).toBe 'source.cpp'

    it "tokenizes this with `.this` class", ->
      {tokens} = grammar.tokenizeLine 'this.x'
      expect(tokens[0]).toEqual value: 'this', scopes: ['source.cpp', 'variable.language.this.cpp']

    it "tokenizes classes", ->
      lines = grammar.tokenizeLines '''
        class Thing {
          int x;
        }
      '''
      expect(lines[0][0]).toEqual value: 'class', scopes: ['source.cpp', 'meta.class-struct-block.cpp', 'storage.type.cpp']
      expect(lines[0][2]).toEqual value: 'Thing', scopes: ['source.cpp', 'meta.class-struct-block.cpp', 'entity.name.type.cpp']

    it "tokenizes 'extern C'", ->
      lines = grammar.tokenizeLines '''
        extern "C" {
        #include "legacy_C_header.h"
        }
      '''
      expect(lines[0][0]).toEqual value: 'extern', scopes: ['source.cpp', 'meta.extern-block.cpp', 'storage.modifier.cpp']
      expect(lines[0][2]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[0][3]).toEqual value: 'C', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp']
      expect(lines[0][4]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[0][6]).toEqual value: '{', scopes: ['source.cpp', 'meta.extern-block.cpp', 'punctuation.section.block.begin.bracket.curly.mil']
      expect(lines[1][0]).toEqual value: '#', scopes: ['source.cpp', 'meta.extern-block.cpp', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil', 'punctuation.definition.directive.mil']
      expect(lines[1][1]).toEqual value: 'include', scopes: ['source.cpp', 'meta.extern-block.cpp', 'meta.preprocessor.include.mil', 'keyword.control.directive.include.mil']
      expect(lines[1][3]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil', 'punctuation.definition.string.begin.mil']
      expect(lines[1][4]).toEqual value: 'legacy_C_header.h', scopes: ['source.cpp', 'meta.extern-block.cpp', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil']
      expect(lines[1][5]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'meta.preprocessor.include.mil', 'string.quoted.double.include.mil', 'punctuation.definition.string.end.mil']
      expect(lines[2][0]).toEqual value: '}', scopes: ['source.cpp', 'meta.extern-block.cpp', 'punctuation.section.block.end.bracket.curly.mil']

      lines = grammar.tokenizeLines '''
        #ifdef __cplusplus
        extern "C" {
        #endif
          // legacy C code here
        #ifdef __cplusplus
        }
        #endif
      '''
      expect(lines[0][0]).toEqual value: '#', scopes: ['source.cpp', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
      expect(lines[0][1]).toEqual value: 'ifdef', scopes: ['source.cpp', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
      expect(lines[0][3]).toEqual value: '__cplusplus', scopes: ['source.cpp', 'meta.preprocessor.mil', 'entity.name.function.preprocessor.mil']
      expect(lines[1][0]).toEqual value: 'extern', scopes: ['source.cpp', 'meta.extern-block.cpp', 'storage.modifier.cpp']
      expect(lines[1][2]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[1][3]).toEqual value: 'C', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp']
      expect(lines[1][4]).toEqual value: '"', scopes: ['source.cpp', 'meta.extern-block.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[1][6]).toEqual value: '{', scopes: ['source.cpp', 'meta.extern-block.cpp', 'punctuation.section.block.begin.bracket.curly.mil']
      expect(lines[2][0]).toEqual value: '#', scopes: ['source.cpp', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
      expect(lines[2][1]).toEqual value: 'endif', scopes: ['source.cpp', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
      expect(lines[3][1]).toEqual value: '//', scopes: ['source.cpp', 'comment.line.double-slash.cpp', 'punctuation.definition.comment.cpp']
      expect(lines[3][2]).toEqual value: ' legacy C code here', scopes: ['source.cpp', 'comment.line.double-slash.cpp']
      expect(lines[4][0]).toEqual value: '#', scopes: ['source.cpp', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
      expect(lines[4][1]).toEqual value: 'ifdef', scopes: ['source.cpp', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']
      expect(lines[5][0]).toEqual value: '}', scopes: ['source.cpp']
      expect(lines[6][0]).toEqual value: '#', scopes: ['source.cpp', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil', 'punctuation.definition.directive.mil']
      expect(lines[6][1]).toEqual value: 'endif', scopes: ['source.cpp', 'meta.preprocessor.mil', 'keyword.control.directive.conditional.mil']

    it "tokenizes UTF string escapes", ->
      lines = grammar.tokenizeLines '''
        string str = U"\\U01234567\\u0123\\"\\0123\\x123";
      '''
      expect(lines[0][0]).toEqual value: 'string str ', scopes: ['source.cpp']
      expect(lines[0][1]).toEqual value: '=', scopes: ['source.cpp', 'keyword.operator.assignment.mil']
      expect(lines[0][3]).toEqual value: 'U', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp', 'meta.encoding.cpp']
      expect(lines[0][4]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[0][5]).toEqual value: '\\U01234567', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
      expect(lines[0][6]).toEqual value: '\\u0123', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
      expect(lines[0][7]).toEqual value: '\\"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
      expect(lines[0][8]).toEqual value: '\\012', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
      expect(lines[0][9]).toEqual value: '3', scopes: ['source.cpp', 'string.quoted.double.cpp']
      expect(lines[0][10]).toEqual value: '\\x123', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.character.escape.cpp']
      expect(lines[0][11]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[0][12]).toEqual value: ';', scopes: ['source.cpp', 'punctuation.terminator.statement.mil']

    it "tokenizes % format specifiers", ->
      {tokens} = grammar.tokenizeLine '"%d"'
      expect(tokens[0]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp']
      expect(tokens[1]).toEqual value: '%d', scopes: ['source.cpp', 'string.quoted.double.cpp', 'constant.other.placeholder.mil']
      expect(tokens[2]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.end.cpp']

      {tokens} = grammar.tokenizeLine '"%"'
      expect(tokens[0]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp']
      expect(tokens[1]).toEqual value: '%', scopes: ['source.cpp', 'string.quoted.double.cpp', 'invalid.illegal.placeholder.mil']
      expect(tokens[2]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.end.cpp']

      {tokens} = grammar.tokenizeLine '"%" PRId32'
      expect(tokens[0]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.begin.cpp']
      expect(tokens[1]).toEqual value: '%', scopes: ['source.cpp', 'string.quoted.double.cpp']
      expect(tokens[2]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.cpp', 'punctuation.definition.string.end.cpp']

    it "tokenizes raw string literals", ->
      lines = grammar.tokenizeLines '''
        string str = R"test(
          this is \"a\" test 'string'
        )test";
      '''
      expect(lines[0][0]).toEqual value: 'string str ', scopes: ['source.cpp']
      expect(lines[0][3]).toEqual value: 'R"test(', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[1][0]).toEqual value: '  this is "a" test \'string\'', scopes: ['source.cpp', 'string.quoted.double.raw.cpp']
      expect(lines[2][0]).toEqual value: ')test"', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[2][1]).toEqual value: ';', scopes: ['source.cpp', 'punctuation.terminator.statement.mil']

    it "errors on long raw string delimiters", ->
      lines = grammar.tokenizeLines '''
        string str = R"01234567890123456()01234567890123456";
      '''
      expect(lines[0][0]).toEqual value: 'string str ', scopes: ['source.cpp']
      expect(lines[0][3]).toEqual value: 'R"', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[0][4]).toEqual value: '01234567890123456', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp', 'invalid.illegal.delimiter-too-long.cpp']
      expect(lines[0][5]).toEqual value: '(', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.begin.cpp']
      expect(lines[0][6]).toEqual value: ')', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[0][7]).toEqual value: '01234567890123456', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp', 'invalid.illegal.delimiter-too-long.cpp']
      expect(lines[0][8]).toEqual value: '"', scopes: ['source.cpp', 'string.quoted.double.raw.cpp', 'punctuation.definition.string.end.cpp']
      expect(lines[0][9]).toEqual value: ';', scopes: ['source.cpp', 'punctuation.terminator.statement.mil']

    it "tokenizes destructors", ->
      {tokens} = grammar.tokenizeLine('~Foo() {}')
      expect(tokens[0]).toEqual value: '~Foo', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'entity.name.function.cpp']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'punctuation.definition.parameters.begin.mil']
      expect(tokens[2]).toEqual value: ')', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'punctuation.definition.parameters.end.mil']
      expect(tokens[4]).toEqual value: '{', scopes: ['source.cpp', 'meta.block.mil', 'punctuation.section.block.begin.bracket.curly.mil']
      expect(tokens[5]).toEqual value: '}', scopes: ['source.cpp', 'meta.block.mil', 'punctuation.section.block.end.bracket.curly.mil']

      {tokens} = grammar.tokenizeLine('Foo::~Bar() {}')
      expect(tokens[0]).toEqual value: 'Foo::~Bar', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'entity.name.function.cpp']
      expect(tokens[1]).toEqual value: '(', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'punctuation.definition.parameters.begin.mil']
      expect(tokens[2]).toEqual value: ')', scopes: ['source.cpp', 'meta.function.destructor.cpp', 'punctuation.definition.parameters.end.mil']
      expect(tokens[4]).toEqual value: '{', scopes: ['source.cpp', 'meta.block.mil', 'punctuation.section.block.begin.bracket.curly.mil']
      expect(tokens[5]).toEqual value: '}', scopes: ['source.cpp', 'meta.block.mil', 'punctuation.section.block.end.bracket.curly.mil']

    describe "digit separators", ->
      it "recognizes numbers with digit separators", ->
        {tokens} = grammar.tokenizeLine "1'000"
        expect(tokens[0]).toEqual value: "1'000", scopes: ['source.cpp', 'constant.numeric.mil']

        {tokens} = grammar.tokenizeLine "123'456.500'000e-1'5"
        expect(tokens[0]).toEqual value: "123'456.500'000e-1'5", scopes: ['source.cpp', 'constant.numeric.mil']

        {tokens} = grammar.tokenizeLine "0x1234'5678"
        expect(tokens[0]).toEqual value: "0x1234'5678", scopes: ['source.cpp', 'constant.numeric.mil']

        {tokens} = grammar.tokenizeLine "0'123'456"
        expect(tokens[0]).toEqual value: "0'123'456", scopes: ['source.cpp', 'constant.numeric.mil']

        {tokens} = grammar.tokenizeLine "0b1100'0011'1111'0000"
        expect(tokens[0]).toEqual value: "0b1100'0011'1111'0000", scopes: ['source.cpp', 'constant.numeric.mil']

      it "does not tokenize single quotes at the beginning or end of numbers as digit separators", ->
        {tokens} = grammar.tokenizeLine "'1000"
        expect(tokens[0]).toEqual value: "'", scopes: ['source.cpp', 'string.quoted.single.mil', 'punctuation.definition.string.begin.mil']
        expect(tokens[1]).toEqual value: "1000", scopes: ['source.cpp', 'string.quoted.single.mil']

        {tokens} = grammar.tokenizeLine "1000'"
        expect(tokens[0]).toEqual value: "1000", scopes: ['source.cpp', 'constant.numeric.mil']
        expect(tokens[1]).toEqual value: "'", scopes: ['source.cpp', 'string.quoted.single.mil', 'punctuation.definition.string.begin.mil']

    describe "comments", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine '// comment'
        expect(tokens[0]).toEqual value: '//', scopes: ['source.cpp', 'comment.line.double-slash.cpp', 'punctuation.definition.comment.cpp']
        expect(tokens[1]).toEqual value: ' comment', scopes: ['source.cpp', 'comment.line.double-slash.cpp']

        lines = grammar.tokenizeLines '''
          // separated\\
          comment
        '''
        expect(lines[0][0]).toEqual value: '//', scopes: ['source.cpp', 'comment.line.double-slash.cpp', 'punctuation.definition.comment.cpp']
        expect(lines[0][1]).toEqual value: ' separated', scopes: ['source.cpp', 'comment.line.double-slash.cpp']
        expect(lines[0][2]).toEqual value: '\\', scopes: ['source.cpp', 'comment.line.double-slash.cpp', 'constant.character.escape.line-continuation.mil']
        expect(lines[1][0]).toEqual value: 'comment', scopes: ['source.cpp', 'comment.line.double-slash.cpp']

        lines = grammar.tokenizeLines '''
          // The space character \x20 is used to prevent stripping trailing whitespace
          // not separated\\\x20
          comment
        '''
        expect(lines[1][0]).toEqual value: '//', scopes: ['source.cpp', 'comment.line.double-slash.cpp', 'punctuation.definition.comment.cpp']
        expect(lines[1][1]).toEqual value: ' not separated\\ ', scopes: ['source.cpp', 'comment.line.double-slash.cpp']
        expect(lines[2][0]).toEqual value: 'comment', scopes: ['source.cpp']

    describe "operators", ->
      it "tokenizes ternary operators with namespace resolution", ->
        {tokens} = grammar.tokenizeLine('a ? ns::b : ns::c')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.cpp']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.cpp', 'keyword.operator.ternary.mil']
        expect(tokens[2]).toEqual value: ' ns', scopes: ['source.cpp']
        expect(tokens[3]).toEqual value: '::', scopes: ['source.cpp', 'punctuation.separator.namespace.access.cpp']
        expect(tokens[4]).toEqual value: 'b ', scopes: ['source.cpp']
        expect(tokens[5]).toEqual value: ':', scopes: ['source.cpp', 'keyword.operator.ternary.mil']
        expect(tokens[6]).toEqual value: ' ns', scopes: ['source.cpp']
        expect(tokens[7]).toEqual value: '::', scopes: ['source.cpp', 'punctuation.separator.namespace.access.cpp']
        expect(tokens[8]).toEqual value: 'c', scopes: ['source.cpp']
