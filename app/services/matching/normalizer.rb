module Matching
  # Canonicalizes a raw supplier product name so it can be compared against
  # the catalog: case/accents/whitespace get folded away and common unit
  # abbreviations ("500ML", "500 ml", "500cc") collapse to one spelling.
  # It does not fix typos or missing spaces — that's what the trigram
  # strategy is for.
  class Normalizer
    UNIT_ALIASES = {
      "ml" => "ml", "mls" => "ml", "cc" => "ml",
      "l" => "l", "lt" => "l", "lts" => "l", "litro" => "l", "litros" => "l",
      "g" => "g", "gr" => "g", "grs" => "g", "gramo" => "g", "gramos" => "g",
      "kg" => "kg", "kgs" => "kg", "kilo" => "kg", "kilos" => "kg",
      "un" => "un", "und" => "un", "unid" => "un", "unidad" => "un", "unidades" => "un",
      "oz" => "oz"
    }.freeze

    UNIT_PATTERN = /(\d+(?:[.,]\d+)?)\s*(#{UNIT_ALIASES.keys.sort_by { |k| -k.length }.join('|')})\b/i

    def self.call(text) = new(text).call

    def initialize(text)
      @text = text.to_s
    end

    def call
      value = strip_accents(@text)
      value = value.downcase
      value = normalize_units(value)
      value = strip_punctuation(value)
      value.squish
    end

    private

    def strip_accents(value)
      value.unicode_normalize(:nfkd).gsub(/[̀-ͯ]/, "")
    end

    def normalize_units(value)
      value.gsub(UNIT_PATTERN) do
        number = Regexp.last_match(1).tr(",", ".")
        unit = UNIT_ALIASES.fetch(Regexp.last_match(2).downcase)
        "#{number}#{unit}"
      end
    end

    def strip_punctuation(value)
      value = value.gsub(/[^a-z0-9\s.]/, " ")
      value.gsub(/(?<!\d)\.(?!\d)/, " ")
    end
  end
end
