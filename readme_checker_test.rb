require 'rubygems'
require 'bundler/setup'
require 'test-unit'
require 'nokogiri'
require 'kramdown'
require 'pry'

class ReadmeCheckerTest < Test::Unit::TestCase
  def readme
    @readme ||= File.read('./README.md')
  end

  def readme_as_html
    @readme_as_html ||= Kramdown::Document.new(readme).to_html
  end

  def elements
    @elements ||= Nokogiri::HTML(readme_as_html).css("h3 + ul")
                    .map { |e| e.css("li a:first-child") }
  end

  def test_exists_items
    assert(false, "Nenhum canal foi encontrado no README.md") if elements.size == 0
  end

  def test_minimum_items_in_categories
    categories_title = Nokogiri::HTML(readme_as_html).css("h3")
    elements.each_with_index do |elem, x|
      assert(false, "A categoria #{categories_title[x].text} possui menos de 3 canais.") if elem.size < 3
    end
  end

  def test_alphabetic_order
    elem_text = -> (node) { node.map { |elem| elem.text.downcase } }
    channels = elements.map(&elem_text)
    sorted = channels.map { |c| c.sort }

    channels.each_with_index do |group, x|
      group.each_with_index do |channel, y|
        assert(false, "O canal '#{sorted[x][y]}' deve vir antes de '#{channel}'") if sorted[x][y] != channel
      end
    end
  end

  def test_duplicated_links
    links_value = ->(node) { node.map { |elem| elem.attributes['href'].value } }
    links = {}
    elements.map(&links_value).flatten.each_with_index do |link, x|
      assert(false, "O link '#{link}' está duplicado") if links[link]
      links[link] = true
    end
  end
end
