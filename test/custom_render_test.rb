# coding: UTF-8
require 'test_helper'

class CustomRenderTest < Redcarpet::TestCase
  class SimpleRender < Redcarpet::Render::HTML
    def emphasis(text)
      if @options[:no_intra_emphasis]
        return %(<em class="no_intra_emphasis">#{text}</em>)
      end

      %(<em class="cool">#{text}</em>)
    end

    def header(text, level)
      "My little poney" if @options[:with_toc_data]
    end
  end

  def test_simple_overload
    md = Redcarpet::Markdown.new(SimpleRender)
    assert_equal "<p>This is <em class=\"cool\">just</em> a test</p>\n",
      md.render("This is *just* a test")
  end

  def test_renderer_options
    parser = Redcarpet::Markdown.new(SimpleRender.new(with_toc_data: true))
    output = parser.render("# A title")

    assert_match "My little poney", output
  end

  def test_markdown_options
    parser = Redcarpet::Markdown.new(SimpleRender, no_intra_emphasis: true)
    output = parser.render("*foo*")

    assert_match "no_intra_emphasis", output
  end

  def test_original_options_hash_is_not_mutated
    options = { with_toc_data: true }
    render  = SimpleRender.new(options)
    parser  = Redcarpet::Markdown.new(render, tables: true)

    computed_options = render.instance_variable_get(:"@options")

    refute_equal computed_options.object_id, options.object_id
  end

  class NilPreprocessRenderer < Redcarpet::Render::HTML
    def preprocess(fulldoc)
      nil
    end
  end

  def test_preprocess_returning_nil
    md = Redcarpet::Markdown.new(NilPreprocessRenderer)
    assert_equal(nil,md.render("Anything"))
  end

  def test_base_render_without_quote_callback
    # Regression test for https://github.com/vmg/redcarpet/issues/569
    render = Class.new(Redcarpet::Render::Base)
    parser = Redcarpet::Markdown.new render.new, quote: true

    assert_equal "", parser.render(%(a "quote"))
  end

  def test_table_cell_callback_having_either_two_or_three_args
    two = Class.new(Redcarpet::Render::HTML) do
      def table_cell(content, alignment)
        %(<td>#{content}</td>)
      end
    end

    three = Class.new(Redcarpet::Render::HTML) do
      def table_cell(content, alignment, header)
        tag = header ? "th" : "td"

        %(<#{tag}>#{content}</#{tag}>)
      end
    end

    markdown = <<-Md.chomp.strip_heredoc
      | A | B |
      |---|---|
      | C | D |
    Md

    first_parser = Redcarpet::Markdown.new(two.new, tables: true)
    second_parser = Redcarpet::Markdown.new(three.new, tables: true)

    first_output = first_parser.render(markdown)
    second_output = second_parser.render(markdown)

    assert { first_output.include?("<td>A</td>") }
    assert { first_output.include?("<td>B</td>") }

    assert { second_output.include?("<th>A</th>") }
    assert { second_output.include?("<th>B</th>") }

    [first_output, second_output].each do |output|
      assert { output.include?("<td>C</td>") }
      assert { output.include?("<td>D</td>") }
    end
  end

  def test_link_reference_missing

    custom = Class.new(Redcarpet::Render::HTML) do

      def emphasis(text)
        %(<em class="custom">#{text}</em>)
      end

      def dangling_link_ref(text)
        %(<a href="https://example.com/#{text}">#{text}</a>)
      end
    end

    #render = Class.new(Redcarpet::Render::Base)
    #custom_parser = Redcarpet::Markdown.new(custom.new)

    default = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    md = Redcarpet::Markdown.new(custom)

    # dangling references are rendered as plain text by default
    assert_equal %{<p>test [ref] text_after</p>\n}, default.render("test [ref] text_after")
    assert_equal %{<p>test [ref][ref2] text_after</p>\n}, default.render("test [ref][ref2] text_after")

    assert_equal %{<p>test <em class="custom">ref</em></p>\n}, md.render("test *ref*")
    assert_equal %{<p>test <a href="https://example.com/ref">ref</a></p>\n}, md.render("test [ref]")
    assert_equal %{<p>test <a href="https://example.com/ref">ref</a><a href="https://example.com/ref2">ref2</a></p>\n}, md.render("test [ref][ref2]")
    assert_equal %{<p>test <a href="https://example.com/ref">ref</a> text_after</p>\n}, md.render("test [ref] text_after")

  end
end
