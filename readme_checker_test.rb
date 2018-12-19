require 'test/unit'
require 'kramdown'
require 'nokogiri'

class ReadmeCheckerTest < Test::Unit::TestCase
  def readme
    @readme ||= File.read('./README.md')
  end

  def readme_as_html
    @readme_as_html ||= Kramdown::Document.new(readme).to_html
  end

  def elements
    @elements ||= Nokogiri::HTML(readme_as_html)
                    .css("p a:first-child")
  end

  def test_alphabetic_order
    elem_text = -> (elem) { elem.text.downcase }
    channels = elements.map(&elem_text)
    sorted = channels.sort

    channels.each_with_index do |channel, x|
      assert(false, "O canal '#{channel}' não esta ordenado corretamente. O esperado seria: '#{sorted[x]}'") if sorted[x] != channel
    end
  end

  def test_duplicated_links
    links_value = ->(elem) { elem.attributes['href'].value }
    links = {}
    elements.map(&links_value).each_with_index do |link, x|
      assert(false, "O link '#{link}' está duplicado") if links[link]
      links[link] = true
    end
  end
end
