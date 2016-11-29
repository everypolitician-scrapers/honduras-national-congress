#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('li.item-181 ul li a').each do |a|
    party = a.text.tidy
    next unless party.include? 'Bancada'
    scrape_party(URI.join(url, a.attr('href')), party)
  end
end

def scrape_party(url, party)
  puts party.to_s
  noko = noko_for(url)
  noko.xpath('//div[@class="item-page"]//table[.//a[img]]').each do |table|
    trs = table.css('tr')
    trs[0].css('td').zip( trs[1].css('td') ).each do |person|
      img_node, name_node = *person
      next if name_node.text.to_s.tidy.empty?
      data = { 
        name: name_node.text.tidy,
        image: img_node.css('img/@src').text,
        party: party,
        source: img_node.css('a/@href').text,
      }
      %i(image source).each { |i| data[i] = URI.join(url, URI.escape(data[i])).to_s unless data[i].to_s.empty? }
      ScraperWiki.save_sqlite([:name, :party], data)
    end
  end
end

scrape_list('http://congresonacional.hn/index.php/conozca-su-diputado/la-junta-directiva')
