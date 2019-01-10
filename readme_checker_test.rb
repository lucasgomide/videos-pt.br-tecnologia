require 'rubygems'
require 'bundler'
Bundler.require(:default)

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

  def remove_acentos(nome)
    return nome.tr("á|ã|Á|Ã","a").tr("é|ê|É|Ê","e").tr("í|Í|","i").tr("ó|Ó|ô|Ô", "o").tr("ú|Ú","u");
  end

  def test_alphabetic_order
    elem_text = -> (node) { node.map { |elem| elem.text.downcase } }
    channels = elements.map(&elem_text)
    sorted = channels.map { |c| c.sort }

    channels.each_with_index do |group, x|
      group.each_with_index do |channel, y|
        
        canal_1 = remove_acentos(sorted[x][y]);
        canal_2 = remove_acentos(channel);
        #group.each_with_index[y] = channel;

        assert(false, "O canal '#{canal_1}' deve vir antes de '#{canal_2}'") if canal_1 != canal_2
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

  def test_tags_presence
    items = Nokogiri::HTML(readme_as_html).css("h3 + ul li")

    items.each do |item|
      assert(false, "O canal #{item.at_css('a').text} não possui tags. Insira as tags relevantes para este canal. Confira a Contributing Guideline e verifique o formato esperado lá.") unless item.at_css('em')
    end
  end

  def test_description_presence
    items = Nokogiri::HTML(readme_as_html).css("h3 + ul li")

    items.each do |item|
      channel_title = item.at_css('a').text
      item.css('em, a').remove
      text = item.text.strip
      assert(false, "O canal #{channel_title} não possui descrição.") if text.empty?
      assert(false, "A descrição do canal #{channel_title} não segue as diretrizes da Contributing Guideline. Deve começar com - (hífen) e terminar com . (ponto final).") if text[0] != '-' || text[-1] != "."
    end
  end

  def test_success_links
    links_value = ->(node) { node.map { |elem| elem.attributes['href'].value } }
    urls = elements.map(&links_value).flatten

    hydra = Typhoeus::Hydra.new
    failed_requests = []
    urls.each do |url|
      request = Typhoeus::Request.new(url)
      request.on_complete do |response|
        failed_requests << response.effective_url if response.failure?
      end
      hydra.queue(request)
    end
    hydra.run

    assert(false, "As requests para os canais #{failed_requests.join(',')} falharam") if failed_requests.size > 0
  end

  def test_link_starts_with
    links_value = ->(node) { node.map { |elem| elem.attributes['href'].value } }
    links = elements.map(&links_value).flatten

    links.each do |link|
      assert(false, "O link '#{link}' não possui o protocolo ou dominio específicado na Contributing Guideline. O esperado é que o link comece com 'https://www.youtube.com'") unless link =~ /^https\:\/\/www\.youtube\.com/
    end
  end
end
