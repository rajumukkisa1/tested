# frozen_string_literal: true

require 'gettext_i18n_rails_js/parser/javascript'
require 'json'

module GettextI18nRailsJs
  module Parser
    module Javascript
      # This is required to tell the `rake gettext:find` script to use the Javascript
      # parser for *.vue files.
      #
      # Overwrites: https://github.com/webhippie/gettext_i18n_rails_js/blob/46c58db6d2053a4f5f36a0eb024ea706ff5707cb/lib/gettext_i18n_rails_js/parser/javascript.rb#L36
      def target?(file)
        [
          ".js",
          ".jsx",
          ".vue"
        ].include? ::File.extname(file)
      end

      def collect_for(file)
        gettext_messages_by_file[file] || []
      end

      private

      def gettext_messages_by_file
        @gettext_messages_by_file ||= Gitlab::Json.parse(load_messages)
      end

      def load_messages
        `node scripts/frontend/extract_gettext_all.js --all`
      end
    end
  end
end

class PoToJson
  # This is required to modify the JS locale file output to our import needs
  # Overwrites: https://github.com/webhippie/po_to_json/blob/master/lib/po_to_json.rb#L46
  def generate_for_jed(language, overwrite = {})
    @options = parse_options(overwrite.merge(language: language))
    @parsed ||= inject_meta(parse_document)

    generated = build_json_for(build_jed_for(@parsed))
    [
      "window.translations = #{generated};"
    ].join(" ")
  end
end
