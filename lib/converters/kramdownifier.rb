require 'nokogiri'
require_relative 'link.rb'
# Converts input HTML to kramdown
module Kramdownifier
  include LinkConverter

  DEFAULT_OPTIONS =
    { html_to_native: true, line_width: 1000, input: 'html' }.freeze

  def kramdownify(string, options = {})
    document = Kramdown::Document.new(string, DEFAULT_OPTIONS.merge(options))
    document.to_kramdown
  end

  # For parse options, trefer tohttps://nokogiri.org/tutorials/parsing_an_html_xml_document.html
  def parse_file(absolute_path)
    content = File.open(absolute_path)
    Nokogiri::XML(content) { |config| config.nocdata }
  end

  def search_by(selector)
    doc.search selector
  end

  def to_xml
    doc.to_xml
  end

  def internal_links
    search_by '//a[not(starts-with(@href, "http"))]'
  end

  def images
    search_by 'img'
  end

  def convert_internal_links
    internal_links.each do |link|
      href = link['href']
      next unless href
      link['href'] =
        convert_relative_url link: href,
                             abs_path: absolute_path,
                             base_dir: base_dir
      link.replace link.children if removed?(link['href'])
    end
  end

  def remove_empty_links
    internal_links
  end

  def convert_links_to_images
    images.each do |img|
      src = img['src']
      next unless src
      img['src'] =
        convert_img_src link: src
    end
  end

  def kramdown_content
    puts "Kramdownifying #{relative_path}"
    puts 'Kramdownifier: Converting includes'
    convert_includes
    puts 'Finished converting includes'
    puts 'Kramdownifier: Converting variables'
    convert_variables
    puts 'Finished converting variables'
    puts 'Kramdownifier: Escaping {{text}}'
    safe_double_braced_content
    puts 'Finished escaping {{text}}'
    puts 'Kramdownifier: converting HTML to Kramdown'
    content = kramdownify search_by('/html/body').to_xml
    puts 'Finished converting HTML to Kramdown'
    content
  end

  def includes
    search_by 'include'
  end

  def variables
    search_by 'variable[name^="MyVariables.Product"]'
  end

  def convert_includes
    includes.each do |element|
      element.node_name = 'p'
      link = element['src']
      converted_link = convert_include_src link: link
      element.content = "{% include #{converted_link} %}"
      element.remove_attribute 'src'
    end
  end

  def convert_variables
    variables.each do |node|
      node.replace 'Magento'
    end
  end

  def text_nodes_with_double_braced_content
    search_by '//text()[contains(.,"{{")]'
  end

  def safe_double_braced_content
    text_nodes_with_double_braced_content.each do |node|
      old_content = node.content
      safe_content = '{% raw %}' + old_content + '{% endraw %}'
      node.content = safe_content
    end
  end
end
