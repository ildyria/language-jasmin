TextEditor = null
buildTextEditor = (params) ->
  if atom.workspace.buildTextEditor?
    atom.workspace.buildTextEditor(params)
  else
    TextEditor ?= require('atom').TextEditor
    new TextEditor(params)

describe "Language-Jaz", ->
  grammar = null

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-jaz')

  describe "Jasmin", ->
    beforeEach ->
      grammar = atom.grammars.grammarForScopeName('source.jaz')

    it "parses the grammar", ->
      expect(grammar).toBeTruthy()
      expect(grammar.scopeName).toBe 'source.jaz'

    it "tokenizes punctuation", ->
      {tokens} = grammar.tokenizeLine 'hi;'
      expect(tokens[1]).toEqual value: ';', scopes: ['source.jaz', 'punctuation.terminator.statement.jaz']

      {tokens} = grammar.tokenizeLine 'a[b]'
      expect(tokens[1]).toEqual value: '[', scopes: ['source.jaz', 'punctuation.definition.begin.bracket.square.jaz']
      expect(tokens[3]).toEqual value: ']', scopes: ['source.jaz', 'punctuation.definition.end.bracket.square.jaz']

      {tokens} = grammar.tokenizeLine 'a, b'
      expect(tokens[1]).toEqual value: ',', scopes: ['source.jaz', 'punctuation.separator.delimiter.jaz']

    it "tokenizes functions", ->
      lines = grammar.tokenizeLines '''
        int something(int param) {
          return 0;
        }
      '''
      expect(lines[0][0]).toEqual value: 'int', scopes: ['source.jaz', 'storage.type.jaz']
      expect(lines[0][2]).toEqual value: 'something', scopes: ['source.jaz', 'meta.function.jaz', 'entity.name.function.jaz']
      expect(lines[0][3]).toEqual value: '(', scopes: ['source.jaz', 'meta.function.jaz', 'punctuation.section.parameters.begin.bracket.round.jaz']
      expect(lines[0][4]).toEqual value: 'int', scopes: ['source.jaz', 'meta.function.jaz', 'storage.type.jaz']
      expect(lines[0][6]).toEqual value: ')', scopes: ['source.jaz', 'meta.function.jaz', 'punctuation.section.parameters.end.bracket.round.jaz']
      expect(lines[0][8]).toEqual value: '{', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.section.block.begin.bracket.curly.jaz']
      expect(lines[1][1]).toEqual value: 'return', scopes: ['source.jaz', 'meta.block.jaz', 'keyword.control.jaz']
      expect(lines[1][3]).toEqual value: '0', scopes: ['source.jaz', 'meta.block.jaz', 'constant.numeric.jaz']
      expect(lines[2][0]).toEqual value: '}', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.section.block.end.bracket.curly.jaz']

    # it "tokenizes various _t types", ->
    #   {tokens} = grammar.tokenizeLine 'size_t var;'
    #   expect(tokens[0]).toEqual value: 'size_t', scopes: ['source.jaz', 'support.type.sys-types.jaz']
    #
    #   {tokens} = grammar.tokenizeLine 'pthread_t var;'
    #   expect(tokens[0]).toEqual value: 'pthread_t', scopes: ['source.jaz', 'support.type.pthread.jaz']
    #
    #   {tokens} = grammar.tokenizeLine 'int32_t var;'
    #   expect(tokens[0]).toEqual value: 'int32_t', scopes: ['source.jaz', 'support.type.stdint.jaz']
    #
    #   {tokens} = grammar.tokenizeLine 'myType_t var;'
    #   expect(tokens[0]).toEqual value: 'myType_t', scopes: ['source.jaz', 'support.type.posix-reserved.jaz']

    it "tokenizes 'line continuation' character", ->
      {tokens} = grammar.tokenizeLine 'ma' + '\\' + '\n' + 'in(){};'
      expect(tokens[0]).toEqual value: 'ma', scopes: ['source.jaz']
      expect(tokens[1]).toEqual value: '\\', scopes: ['source.jaz', 'constant.character.escape.line-continuation.jaz']
      expect(tokens[3]).toEqual value: 'in', scopes: ['source.jaz', 'meta.function.jaz', 'entity.name.function.jaz']

    describe "strings", ->
      it "tokenizes them", ->
        delimsByScope =
          'string.quoted.double.jaz': '"'
          'string.quoted.single.jaz': '\''

        for scope, delim of delimsByScope
          {tokens} = grammar.tokenizeLine delim + 'a' + delim
          expect(tokens[0]).toEqual value: delim, scopes: ['source.jaz', scope, 'punctuation.definition.string.begin.jaz']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.jaz', scope]
          expect(tokens[2]).toEqual value: delim, scopes: ['source.jaz', scope, 'punctuation.definition.string.end.jaz']

          {tokens} = grammar.tokenizeLine delim + 'a' + '\\' + '\n' + 'b' + delim
          expect(tokens[0]).toEqual value: delim, scopes: ['source.jaz', scope, 'punctuation.definition.string.begin.jaz']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.jaz', scope]
          expect(tokens[2]).toEqual value: '\\', scopes: ['source.jaz', scope, 'constant.character.escape.line-continuation.jaz']
          expect(tokens[4]).toEqual value: 'b', scopes: ['source.jaz', scope]
          expect(tokens[5]).toEqual value: delim, scopes: ['source.jaz', scope, 'punctuation.definition.string.end.jaz']

        {tokens} = grammar.tokenizeLine '"%d"'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.jaz', 'string.quoted.double.jaz', 'punctuation.definition.string.begin.jaz']
        expect(tokens[1]).toEqual value: '%d', scopes: ['source.jaz', 'string.quoted.double.jaz', 'constant.other.placeholder.jaz']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.jaz', 'string.quoted.double.jaz', 'punctuation.definition.string.end.jaz']

        {tokens} = grammar.tokenizeLine '"%"'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.jaz', 'string.quoted.double.jaz', 'punctuation.definition.string.begin.jaz']
        expect(tokens[1]).toEqual value: '%', scopes: ['source.jaz', 'string.quoted.double.jaz', 'invalid.illegal.placeholder.jaz']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.jaz', 'string.quoted.double.jaz', 'punctuation.definition.string.end.jaz']

        {tokens} = grammar.tokenizeLine '"%" PRId32'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.jaz', 'string.quoted.double.jaz', 'punctuation.definition.string.begin.jaz']
        expect(tokens[1]).toEqual value: '%', scopes: ['source.jaz', 'string.quoted.double.jaz']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.jaz', 'string.quoted.double.jaz', 'punctuation.definition.string.end.jaz']

        {tokens} = grammar.tokenizeLine '"%" SCNd32'
        expect(tokens[0]).toEqual value: '"', scopes: ['source.jaz', 'string.quoted.double.jaz', 'punctuation.definition.string.begin.jaz']
        expect(tokens[1]).toEqual value: '%', scopes: ['source.jaz', 'string.quoted.double.jaz']
        expect(tokens[2]).toEqual value: '"', scopes: ['source.jaz', 'string.quoted.double.jaz', 'punctuation.definition.string.end.jaz']

    describe "comments", ->
      it "tokenizes them", ->
        {tokens} = grammar.tokenizeLine '/**/'
        expect(tokens[0]).toEqual value: '/*', scopes: ['source.jaz', 'comment.block.jaz', 'punctuation.definition.comment.begin.jaz']
        expect(tokens[1]).toEqual value: '*/', scopes: ['source.jaz', 'comment.block.jaz', 'punctuation.definition.comment.end.jaz']

        {tokens} = grammar.tokenizeLine '/* foo */'
        expect(tokens[0]).toEqual value: '/*', scopes: ['source.jaz', 'comment.block.jaz', 'punctuation.definition.comment.begin.jaz']
        expect(tokens[1]).toEqual value: ' foo ', scopes: ['source.jaz', 'comment.block.jaz']
        expect(tokens[2]).toEqual value: '*/', scopes: ['source.jaz', 'comment.block.jaz', 'punctuation.definition.comment.end.jaz']

        {tokens} = grammar.tokenizeLine '*/*'
        expect(tokens[0]).toEqual value: '*/*', scopes: ['source.jaz', 'invalid.illegal.stray-comment-end.jaz']

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
        expect(tokens[0]).toEqual value: '0b101010', scopes: ['source.jaz', 'constant.numeric.jaz']

    describe "access", ->
      it "tokenizes the dot access operator", ->
        lines = grammar.tokenizeLines '''
          {
            a.
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.jaz', 'meta.block.jaz']
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.dot-access.jaz']

        lines = grammar.tokenizeLines '''
          {
            a.b;
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.jaz', 'meta.block.jaz']
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.dot-access.jaz']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.jaz', 'meta.block.jaz', 'variable.other.member.jaz']

        lines = grammar.tokenizeLines '''
          {
            a.b()
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.jaz', 'meta.block.jaz']
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.dot-access.jaz']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.jaz', 'meta.block.jaz', 'meta.function-call.jaz', 'entity.name.function.jaz']

        lines = grammar.tokenizeLines '''
          {
            a. b;
          }
        '''
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.dot-access.jaz']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.jaz', 'meta.block.jaz', 'variable.other.member.jaz']

        lines = grammar.tokenizeLines '''
          {
            a .b;
          }
        '''
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.dot-access.jaz']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.jaz', 'meta.block.jaz', 'variable.other.member.jaz']

        lines = grammar.tokenizeLines '''
          {
            a . b;
          }
        '''
        expect(lines[1][1]).toEqual value: '.', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.dot-access.jaz']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.jaz', 'meta.block.jaz', 'variable.other.member.jaz']

      it "tokenizes the pointer access operator", ->
        lines = grammar.tokenizeLines '''
          {
            a->b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.pointer-access.jaz']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.jaz', 'meta.block.jaz', 'variable.other.member.jaz']

        lines = grammar.tokenizeLines '''
          {
            a->b()
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.jaz', 'meta.block.jaz']
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.pointer-access.jaz']

        lines = grammar.tokenizeLines '''
          {
            a-> b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.pointer-access.jaz']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.jaz', 'meta.block.jaz', 'variable.other.member.jaz']

        lines = grammar.tokenizeLines '''
          {
            a ->b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.pointer-access.jaz']
        expect(lines[1][2]).toEqual value: 'b', scopes: ['source.jaz', 'meta.block.jaz', 'variable.other.member.jaz']

        lines = grammar.tokenizeLines '''
          {
            a -> b;
          }
        '''
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.pointer-access.jaz']
        expect(lines[1][3]).toEqual value: 'b', scopes: ['source.jaz', 'meta.block.jaz', 'variable.other.member.jaz']

        lines = grammar.tokenizeLines '''
          {
            a->
          }
        '''
        expect(lines[1][0]).toEqual value: '  a', scopes: ['source.jaz', 'meta.block.jaz']
        expect(lines[1][1]).toEqual value: '->', scopes: ['source.jaz', 'meta.block.jaz', 'punctuation.separator.pointer-access.jaz']

    describe "operators", ->
      it "tokenizes the increment operator", ->
        {tokens} = grammar.tokenizeLine('i++')
        expect(tokens[0]).toEqual value: 'i', scopes: ['source.jaz']
        expect(tokens[1]).toEqual value: '++', scopes: ['source.jaz', 'keyword.operator.increment.jaz']

        {tokens} = grammar.tokenizeLine('++i')
        expect(tokens[0]).toEqual value: '++', scopes: ['source.jaz', 'keyword.operator.increment.jaz']
        expect(tokens[1]).toEqual value: 'i', scopes: ['source.jaz']

      it "tokenizes the decrement operator", ->
        {tokens} = grammar.tokenizeLine('i--')
        expect(tokens[0]).toEqual value: 'i', scopes: ['source.jaz']
        expect(tokens[1]).toEqual value: '--', scopes: ['source.jaz', 'keyword.operator.decrement.jaz']

        {tokens} = grammar.tokenizeLine('--i')
        expect(tokens[0]).toEqual value: '--', scopes: ['source.jaz', 'keyword.operator.decrement.jaz']
        expect(tokens[1]).toEqual value: 'i', scopes: ['source.jaz']

      it "tokenizes logical operators", ->
        {tokens} = grammar.tokenizeLine('!a')
        expect(tokens[0]).toEqual value: '!', scopes: ['source.jaz', 'keyword.operator.logical.jaz']
        expect(tokens[1]).toEqual value: 'a', scopes: ['source.jaz']

        operators = ['&&', '||']
        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.jaz']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.jaz', 'keyword.operator.logical.jaz']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.jaz']

      it "tokenizes comparison operators", ->
        operators = ['<=', '>=', '!=', '==', '<', '>' ]

        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.jaz']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.jaz', 'keyword.operator.comparison.jaz']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.jaz']

      it "tokenizes arithmetic operators", ->
        operators = ['+', '-', '*', '/', '%']

        for operator in operators
          {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.jaz']
          expect(tokens[1]).toEqual value: operator, scopes: ['source.jaz', 'keyword.operator.jaz']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.jaz']

      it "tokenizes ternary operators", ->
        {tokens} = grammar.tokenizeLine('a ? b : c')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.jaz']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.jaz', 'keyword.operator.ternary.jaz']
        expect(tokens[2]).toEqual value: ' b ', scopes: ['source.jaz']
        expect(tokens[3]).toEqual value: ':', scopes: ['source.jaz', 'keyword.operator.ternary.jaz']
        expect(tokens[4]).toEqual value: ' c', scopes: ['source.jaz']

      it "tokenizes ternary operators with member access", ->
        {tokens} = grammar.tokenizeLine('a ? b.c : d')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.jaz']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.jaz', 'keyword.operator.ternary.jaz']
        expect(tokens[2]).toEqual value: ' b', scopes: ['source.jaz']
        expect(tokens[3]).toEqual value: '.', scopes: ['source.jaz', 'punctuation.separator.dot-access.jaz']
        expect(tokens[4]).toEqual value: 'c', scopes: ['source.jaz', 'variable.other.member.jaz']
        expect(tokens[5]).toEqual value: ' ', scopes: ['source.jaz']
        expect(tokens[6]).toEqual value: ':', scopes: ['source.jaz', 'keyword.operator.ternary.jaz']
        expect(tokens[7]).toEqual value: ' d', scopes: ['source.jaz']

      it "tokenizes ternary operators with pointer dereferencing", ->
        {tokens} = grammar.tokenizeLine('a ? b->c : d')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.jaz']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.jaz', 'keyword.operator.ternary.jaz']
        expect(tokens[2]).toEqual value: ' b', scopes: ['source.jaz']
        expect(tokens[3]).toEqual value: '->', scopes: ['source.jaz', 'punctuation.separator.pointer-access.jaz']
        expect(tokens[4]).toEqual value: 'c', scopes: ['source.jaz', 'variable.other.member.jaz']
        expect(tokens[5]).toEqual value: ' ', scopes: ['source.jaz']
        expect(tokens[6]).toEqual value: ':', scopes: ['source.jaz', 'keyword.operator.ternary.jaz']
        expect(tokens[7]).toEqual value: ' d', scopes: ['source.jaz']

      it "tokenizes ternary operators with function invocation", ->
        {tokens} = grammar.tokenizeLine('a ? f(b) : c')
        expect(tokens[0]).toEqual value: 'a ', scopes: ['source.jaz']
        expect(tokens[1]).toEqual value: '?', scopes: ['source.jaz', 'keyword.operator.ternary.jaz']
        expect(tokens[2]).toEqual value: ' ', scopes: ['source.jaz']
        expect(tokens[3]).toEqual value: 'f', scopes: ['source.jaz', 'meta.function-call.jaz', 'entity.name.function.jaz']
        expect(tokens[4]).toEqual value: '(', scopes: ['source.jaz', 'meta.function-call.jaz', 'punctuation.section.arguments.begin.bracket.round.jaz']
        expect(tokens[5]).toEqual value: 'b', scopes: ['source.jaz', 'meta.function-call.jaz']
        expect(tokens[6]).toEqual value: ')', scopes: ['source.jaz', 'meta.function-call.jaz', 'punctuation.section.arguments.end.bracket.round.jaz']
        expect(tokens[7]).toEqual value: ' ', scopes: ['source.jaz']
        expect(tokens[8]).toEqual value: ':', scopes: ['source.jaz', 'keyword.operator.ternary.jaz']
        expect(tokens[9]).toEqual value: ' c', scopes: ['source.jaz']

      describe "bitwise", ->
        it "tokenizes bitwise 'not'", ->
          {tokens} = grammar.tokenizeLine('~a')
          expect(tokens[0]).toEqual value: '~', scopes: ['source.jaz', 'keyword.operator.jaz']
          expect(tokens[1]).toEqual value: 'a', scopes: ['source.jaz']

        it "tokenizes shift operators", ->
          {tokens} = grammar.tokenizeLine('>>')
          expect(tokens[0]).toEqual value: '>>', scopes: ['source.jaz', 'keyword.operator.bitwise.shift.jaz']

          {tokens} = grammar.tokenizeLine('<<')
          expect(tokens[0]).toEqual value: '<<', scopes: ['source.jaz', 'keyword.operator.bitwise.shift.jaz']

        it "tokenizes them", ->
          operators = ['|', '^', '&']

          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.jaz']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.jaz', 'keyword.operator.jaz']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.jaz']

      describe "assignment", ->
        it "tokenizes the assignment operator", ->
          {tokens} = grammar.tokenizeLine('a = b')
          expect(tokens[0]).toEqual value: 'a ', scopes: ['source.jaz']
          expect(tokens[1]).toEqual value: '=', scopes: ['source.jaz', 'keyword.operator.assignment.jaz']
          expect(tokens[2]).toEqual value: ' b', scopes: ['source.jaz']

        it "tokenizes compound assignment operators", ->
          operators = ['+=', '-=', '*=', '/=', '%=']
          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.jaz']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.jaz', 'keyword.operator.assignment.compound.jaz']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.jaz']

        it "tokenizes bitwise compound operators", ->
          operators = ['<<=', '>>=', '&=', '^=', '|=']
          for operator in operators
            {tokens} = grammar.tokenizeLine('a ' + operator + ' b')
            expect(tokens[0]).toEqual value: 'a ', scopes: ['source.jaz']
            expect(tokens[1]).toEqual value: operator, scopes: ['source.jaz', 'keyword.operator.assignment.compound.bitwise.jaz']
            expect(tokens[2]).toEqual value: ' b', scopes: ['source.jaz']
