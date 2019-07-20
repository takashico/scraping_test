require 'nokogiri'
require 'open-uri'
require 'csv'

BASE_URL = "https://www.spacemarket.com"

#検索結果のページからの取得
def get_page_urls
  page_urls = []
  puts "データ取得中です・・・"
  (1..10).each do |page|
    sleep(1)
    url = "#{BASE_URL}/search?location=%E6%96%B0%E5%AE%BF%E5%8C%BA&page=#{page}&priceType=HOURLY&address=%E6%9D%B1%E4%BA%AC%E9%83%BD%E6%96%B0%E5%AE%BF%E5%8C%BA"
    data = Nokogiri::HTML(open(url))
    data.xpath('//div[@class="SearchListItem__ListItemInformation-sc-5kcre5-10 dDygVv"]').each do |page_url|
      page_urls << page_url.css('a').attribute('href').value
    end
  end
  return page_urls
end

# 個別ページからのデータ取得
def get_page_data
  all_data = []
  page_data = {}

  page_urls = get_page_urls
  page_urls.each_with_index do |page_url, index|
    sleep(1)
    url = "#{BASE_URL}#{page_url}"
    begin
      data = Nokogiri::HTML(open(url))
      data.xpath('//h1[@class="DetailHeader__PageTitle-sc-1gxcccq-6 gnSlHP"]').each do |title|
        page_data[:title] = title.content
      end
      price = data.xpath('//p[@class="DetailSideBox__DetailText-rv60ft-1 mAKwP"]').map(&:content)
      page_data[:price] = price.join(', ')
      data.xpath('//li[@class="space-head__list-user"]').each do |people|
        page_data[:people] = people.content
      end
      data.xpath('//div[@itemprop="address"]').each do |address|
        page_data[:address] = address.content
      end
      data.xpath('//div[@itemprop="description"]').each do |description|
        page_data[:description] = description.content
      end
      data.xpath('//span[@class="ReputationListHeader__CountNumber-sc-1dnpi95-6 kzATGM"]').each do |favorite|
        page_data[:favorite] = favorite.content
      end
      data.xpath('//source[@class="OptimizedImage__Source-cm63h6-4 bvXIiJ"]').map do |image|
        page_data[:image_url] = image.attribute('srcset').value
      end
      all_data[index] = {title: "#{page_data[:title]}", price: "#{page_data[:price]}", people: "#{page_data[:people]}",
                        address: "#{page_data[:address]}", description: "#{page_data[:description]}",
                        favorite: "#{page_data[:favorite]}", image_url: "#{page_data[:image_url]}"}
    rescue => e
      all_data[index] = {title: "URLにアクセスできませんでした。"}
    end
  end
  return all_data
end

def get_csv(all_data)
  CSV.open("spacemarket_data.csv", "w") do |csv|
    csv << ["id", "タイトル", "説明文", "価格", "収容人数", "住所", "評価", "サムネイル写真のURL"]
    all_data.each_with_index do |data, index|
      csv << ["#{index+1}", "#{data[:title]}", "#{data[:description]}",
              "#{data[:price]}", "#{data[:people]}",
              "#{data[:address]}", "#{data[:favorite]}", "#{data[:image_url]}"]
    end
  end
  puts "csvに出力しました"
end

get_csv(get_page_data)
