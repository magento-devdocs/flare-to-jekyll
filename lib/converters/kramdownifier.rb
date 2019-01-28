require 'nokogiri'
require_relative 'link.rb'
# Converts input HTML to kramdown
module Kramdownifier
  attr_reader :doc

  include LinkConverter

  def initialize(args)
    super
    # Parse a file by filepath using Nokogiri
    @doc = File.open(absolute_path) { |f| Nokogiri::XML(f) }
  end

  DEFAULT_OPTIONS =
    { html_to_native: true, line_width: 1000, input: 'html' }.freeze

  def kramdownify(string, options = {})
    document = Kramdown::Document.new(string, DEFAULT_OPTIONS.merge(options))
    document.to_kramdown
  end

  def empty?
    doc.root.nil?
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
        convert_a_href link: href,
                       abs_path: absolute_path,
                       base_dir: base_dir
    end
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
    kramdownify doc.search('/html/body').to_xml
  end
end
