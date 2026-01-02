class AmazonSidebar < Sidebar
  description \
    "Adds sidebar links to any amazon books linked in the body of the page"
  setting :title,        'Cited books'
  setting :associate_id, 'justasummary-20'
  setting :maxlinks,     4

  attr_accessor :products

  def parse_request(contents, request_params)
    all_products = {}

    contents.to_a.each do |item|
      if item.whiteboard[:amazon_products].is_a?(Hash)
        all_products.merge!(item.whiteboard[:amazon_products])
      end
    end

    # Limit to maxlinks products
    self.products = all_products.first(maxlinks.to_i).to_h
  end
end
