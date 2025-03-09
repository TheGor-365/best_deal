class SearchController < ApplicationController
  require 'nokogiri'
  require 'httparty'

  def index
    @q = Product.ransack(params[:q])
  end

  def results
    @query = params[:query]
    @marketplaces = params[:marketplaces] || ['yandex_market', 'ozon', 'wildberries']
    @products = []

    if @marketplaces.include?('yandex_market')
      parse_yandex_market
    end

    if @marketplaces.include?('ozon')
      parse_ozon
    end

    if @marketplaces.include?('wildberries')
      parse_wildberries
    end

    @products.sort_by! { |product| product[:price] }
    @products = @products.take(50)
    @best_product = @products.min_by { |product| product[:price] }
    calculate_statistics

    ahoy.track 'Search Results', { query: @query, marketplaces: @marketplaces.join(', ') }
  end

  def info
    @products = Product.where(name: params[:name])
    render turbo_stream: turbo_stream.replace('info_modal', partial: 'search/info_modal', locals: { products: @products })
  end

  private

  def parse_yandex_market
    url = "https://market.yandex.ru/search?text=#{@query}"
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)
    doc.css('.n-snippet-card2').each do |card|
      name = card.css('.n-snippet-card2__title a').text.strip
      price = card.css('.n-snippet-card2__price-part').text.strip.gsub(/[^0-9]/, '').to_i
      link = "https://market.yandex.ru" + card.css('.n-snippet-card2__title a')[0]['href']
      description = card.css('.n-snippet-card2__description-text').text.strip
      characteristics = card.css('.n-snippet-card2__characteristics').text.strip
      Product.create(name: name, price: price, link: link, marketplace: 'yandex_market', description: description, characteristics: characteristics)
      @products << { name: name, price: price, link: link, marketplace: 'yandex_market' }
    end
  end

  def parse_ozon
    url = "https://www.ozon.ru/search/?text=#{@query}"
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)
    doc.css('.a2g0.tsBody500 a').each do |card|
        name = card.css('.a2g0.tsBody500 a').text.strip
        price = card.css('.a2g0.tsBody500 a').text.strip.gsub(/[^0-9]/, '').to_i
        link = "https://www.ozon.ru" + card.css('a')[0]['href']
        description = card.css('.a2g0.tsBody500 a').text.strip
        characteristics = card.css('.a2g0.tsBody500 a').text.strip
        Product.create(name: name, price: price, link: link, marketplace: 'ozon', description: description, characteristics: characteristics)
        @products << { name: name, price: price, link: link, marketplace: 'ozon' }
    end
  end

  def parse_wildberries
    url = "https://www.wildberries.ru/catalog/0/search.aspx?search=#{@query}"
    response = HTTParty.get(url)
    doc = Nokogiri::HTML(response.body)
    doc.css('.product-card').each do |card|
        name = card.css('.product-card__brand-name').text.strip + " " + card.css('.product-card__name').text.strip
        price = card.css('.price__lower-price').text.strip.gsub(/[^0-9]/, '').to_i
        link = "https://www.wildberries.ru" + card.css('a')[0]['href']
        description = card.css('.product-card__description').text.strip
        characteristics = card.css('.product-card__characteristics').text.strip
        Product.create(name: name, price: price, link: link, marketplace: 'wildberries', description: description, characteristics: characteristics)
        @products << { name: name, price: price, link: link, marketplace: 'wildberries' }
    end
  end

  def calculate_statistics
    prices = @products.map { |product| product[:price] }
    @min_price = prices.min
    @max_price = prices.max
    @avg_price = prices.sum / prices.size.to_f
    @price_range = @max_price - @min_price
  end
end
