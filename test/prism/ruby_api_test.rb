# frozen_string_literal: true

require_relative "test_helper"

module Prism
  class RubyAPITest < TestCase
    def test_ruby_api
      filepath = __FILE__
      source = File.read(filepath, binmode: true, external_encoding: Encoding::UTF_8)

      assert_equal Prism.lex(source, filepath: filepath).value, Prism.lex_file(filepath).value
      assert_equal Prism.dump(source, filepath: filepath), Prism.dump_file(filepath)

      serialized = Prism.dump(source, filepath: filepath)
      ast1 = Prism.load(source, serialized).value
      ast2 = Prism.parse(source, filepath: filepath).value
      ast3 = Prism.parse_file(filepath).value

      assert_equal_nodes ast1, ast2
      assert_equal_nodes ast2, ast3
    end

    def test_options
      assert_equal "", Prism.parse("__FILE__").value.statements.body[0].filepath
      assert_equal "foo.rb", Prism.parse("__FILE__", filepath: "foo.rb").value.statements.body[0].filepath

      assert_equal 1, Prism.parse("foo").value.statements.body[0].location.start_line
      assert_equal 10, Prism.parse("foo", line: 10).value.statements.body[0].location.start_line

      refute Prism.parse("\"foo\"").value.statements.body[0].frozen?
      assert Prism.parse("\"foo\"", frozen_string_literal: true).value.statements.body[0].frozen?
      refute Prism.parse("\"foo\"", frozen_string_literal: false).value.statements.body[0].frozen?

      assert_kind_of Prism::CallNode, Prism.parse("foo").value.statements.body[0]
      assert_kind_of Prism::LocalVariableReadNode, Prism.parse("foo", scopes: [[:foo]]).value.statements.body[0]
      assert_equal 2, Prism.parse("foo", scopes: [[:foo], []]).value.statements.body[0].depth
    end

    def test_literal_value_method
      assert_equal 123, parse_expression("123").value
      assert_equal 3.14, parse_expression("3.14").value
      assert_equal 42i, parse_expression("42i").value
      assert_equal 42.1ri, parse_expression("42.1ri").value
      assert_equal 3.14i, parse_expression("3.14i").value
      assert_equal 42r, parse_expression("42r").value
      assert_equal 0.5r, parse_expression("0.5r").value
      assert_equal 42ri, parse_expression("42ri").value
      assert_equal 0.5ri, parse_expression("0.5ri").value
    end

    def test_location_join
      recv, args_node, _ = parse_expression("1234 + 567").child_nodes
      arg = args_node.arguments[0]

      joined = recv.location.join(arg.location)
      assert_equal 0, joined.start_offset
      assert_equal 10, joined.length

      assert_raise RuntimeError, "Incompatible locations" do
        arg.location.join(recv.location)
      end

      other_arg = parse_expression("1234 + 567").arguments.arguments[0]

      assert_raise RuntimeError, "Incompatible sources" do
        other_arg.location.join(recv.location)
      end

      assert_raise RuntimeError, "Incompatible sources" do
        recv.location.join(other_arg.location)
      end
    end

    private

    def parse_expression(source)
      Prism.parse(source).value.statements.body.first
    end
  end
end
