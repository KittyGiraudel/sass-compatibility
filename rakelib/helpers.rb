require 'yaml'

class Hash
  def to_partial_yaml
    to_yaml.lines.drop(1).join
  end
end

class String
  def normalize_encoding
    encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  end

  def normalize_css
    lines
      .map(&:normalize_encoding)
      .reject { |s| s[/^@charset/] }
      .reject { |s| s[/^>> /] || s.strip[/-?\^$/] }
      .reject { |s| s.strip[/^on line/] && (s.strip[/stdin$/] || s.strip[/standard input$/]) }
      .reject { |s| s.strip == 'Use --trace for backtrace.' }
      .reject { |s| s.strip == 'Segmentation fault (core dumped)' }
      .join
      .gsub(' of stdin', '')
      .gsub(/^Error: /, '')
      .gsub(/\s+/, ' ')
      .gsub(/ *\{/, " {\n")
      .gsub(/([;,]) */, "\\1\n")
      .gsub(/ *\} */, " }\n")
      .strip
      .chomp('.')
  end
end
