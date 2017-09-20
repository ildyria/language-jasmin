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

    # it "tokenizes various _t types", ->
    #   {tokens} = grammar.tokenizeLine 'size_t var;'
    #   expect(tokens[0]).toEqual value: 'size_t', scopes: ['source.mil', 'support.type.sys-types.mil']
    #
    #   {tokens} = grammar.tokenizeLine 'pthread_t var;'
    #   expect(tokens[0]).toEqual value: 'pthread_t', scopes: ['source.mil', 'support.type.pthread.mil']
    #
    #   {tokens} = grammar.tokenizeLine 'int32_t var;'
    #   expect(tokens[0]).toEqual value: 'int32_t', scopes: ['source.mil', 'support.type.stdint.mil']
    #
    #   {tokens} = grammar.tokenizeLine 'myType_t var;'
    #   expect(tokens[0]).toEqual value: 'myType_t', scopes: ['source.mil', 'support.type.posix-reserved.mil']

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
