require 'net/http'
require 'uri'

module Jekyll

  class RemoteInclude < Liquid::Tag

    VALID_SYNTAX = %r!
      ([\w-]+)\s*=\s*
      (?:"([^"\\]*(?:\\.[^"\\]*)*)"|'([^'\\]*(?:\\.[^'\\]*)*)'|([\w\.-]+))
    !x.freeze
    VARIABLE_SYNTAX = %r!
      (?<variable>[^{]*(\{\{\s*[\w\-\.]+\s*(\|.*)?\}\}[^\s{}]*)+)
      (?<params>.*)
    !mx.freeze

    FULL_VALID_SYNTAX = %r!\A\s*(?:#{VALID_SYNTAX}(?=\s|\z)\s*)*\z!.freeze
    VALID_FILENAME_CHARS = %r!^[\w/\.-]+$!.freeze
    INVALID_SEQUENCES = %r![./]{2,}!.freeze

    def initialize(tag_name, remote_include, tokens)
      super
      matched = markup.strip.match(VARIABLE_SYNTAX)
      if matched
        @file = matched["variable"].strip
        @params = matched["params"].strip
      else
        @file, @params = markup.strip.split(%r!\s+!, 2)
      end
      validate_params if @params
      @remote_include = remote_include
    end

    def parse_params(context)
      params = {}
      markup = @params

      while (match = VALID_SYNTAX.match(markup))
        markup = markup[match.end(0)..-1]

        value = if match[2]
                  match[2].gsub('\\"', '"')
                elsif match[3]
                  match[3].gsub("\\'", "'")
                elsif match[4]
                  context[match[4]]
                end

        params[match[1]] = value
      end
      params
    end

    def open(url)
      Net::HTTP.get(URI.parse(url.strip)).force_encoding 'utf-8'
    end

    def render(context)
      open("#{@remote_include}")
    end

  end
end

Liquid::Template.register_tag('remote_include', Jekyll::RemoteInclude)
