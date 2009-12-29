require OrgRuby.libpath(*%w[org-ruby output_buffer])
require 'cgi'

module Orgmode

  class HtmlOutputBuffer < OutputBuffer

    HtmlBlockTag = {
      :paragraph => "p",
      :ordered_list => "li",
      :unordered_list => "li",
      :table_row => "tr"
    }

    ModeTag = {
      :unordered_list => "ul",
      :ordered_list => "ol",
      :table => "table",
      :blockquote => "blockquote",
      :code => "pre"
    }

    def initialize(output, opts = {})
      super(output)
      if opts[:decorate_title] then
        @title_decoration = " class=\"title\""
      else
        @title_decoration = ""
      end
    end

    def push_mode(mode)
      if ModeTag[mode] then
        output_indentation
        @output << "<#{ModeTag[mode]}>\n" 
        # Entering a new mode obliterates the title decoration
        @title_decoration = ""
      end
      super(mode)
    end

    def pop_mode(mode = nil)
      m = super(mode)
      if ModeTag[m] then
        output_indentation
        @output << "</#{ModeTag[m]}>\n"
      end
    end

    def flush!
      @logger.debug "FLUSH ==========> #{@output_type}"
      escape_buffer!
      if current_mode == :code then
        # Whitespace is significant in :code mode. Always output the buffer
        # and do not do any additional translation.
        @output << @buffer << "\n"
      else
        if (@buffer.length > 0) then
          output_indentation
          @output << "<#{HtmlBlockTag[@output_type]}#{@title_decoration}>" \
            << inline_formatting(@buffer) \
            << "</#{HtmlBlockTag[@output_type]}>\n"
          @title_decoration = ""
        end
      end
      @buffer = ""
    end

    ######################################################################
    private

    # Escapes any HTML content in the output accumulation buffer @buffer.
    def escape_buffer!
      @buffer = CGI.escapeHTML(@buffer)
    end

    def output_indentation
      indent = "  " * (@mode_stack.length - 1)
      @output << indent
    end

    Tags = {
      "*" => { :open => "<b>", :close => "</b>" },
      "/" => { :open => "<i>", :close => "</i>" },
      "_" => { :open => "<span style=\"text-decoration:underline;\">",
        :close => "</span>" },
      "=" => { :open => "<code>", :close => "</code>" },
      "~" => { :open => "<code>", :close => "</code>" },
      "+" => { :open => "<del>", :close => "</del>" }
    }

    # Applies inline formatting rules to a string.
    def inline_formatting(str)
      str.rstrip!
      str = @re_help.rewrite_emphasis(str) do |marker, s|
        "#{Tags[marker][:open]}#{s}#{Tags[marker][:close]}"
      end
      str = @re_help.rewrite_links(str) do |link, text|
        text ||= link
        "<a href=\"#{link}\">#{text}</a>"
      end
      if (@output_type == :table_row) then
        str.gsub!(/^\|\s*/, "<td>")
        str.gsub!(/\s*\|$/, "</td>")
        str.gsub!(/\s*\|\s*/, "</td><td>")
      end
      str
    end

  end                           # class HtmlOutputBuffer
end                             # module Orgmode
