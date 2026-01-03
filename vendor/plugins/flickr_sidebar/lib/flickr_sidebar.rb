# coding: utf-8
require 'net/http'
require 'json'

class FlickrSidebar < Sidebar
  display_name "Flickr Photos"
  description "Display your recent photos from Flickr"

  setting :title, 'Photos'
  setting :flickr_user_id, '', :label => 'Flickr Username or User ID'
  setting :photo_count, '16', :label => 'Number of photos'
  setting :photo_size, 'large_square', :label => 'Photo size', :choices => %w(square large_square thumbnail small medium)
  setting :show_example_content, false, :label => 'Show example content (for preview)', :input_type => :checkbox

  # Example photo data for preview
  ExamplePhoto = Struct.new(:id, :title, :url_sq, :url_q, :url_t, :url_s, :url_m, keyword_init: true)

  EXAMPLE_PHOTOS = [
    ExamplePhoto.new(id: '1', title: 'Mountain Sunrise', url_sq: 'https://picsum.photos/seed/photo1/75/75', url_q: 'https://picsum.photos/seed/photo1/150/150', url_t: 'https://picsum.photos/seed/photo1/100/100', url_s: 'https://picsum.photos/seed/photo1/240/240', url_m: 'https://picsum.photos/seed/photo1/500/500'),
    ExamplePhoto.new(id: '2', title: 'Ocean Waves', url_sq: 'https://picsum.photos/seed/photo2/75/75', url_q: 'https://picsum.photos/seed/photo2/150/150', url_t: 'https://picsum.photos/seed/photo2/100/100', url_s: 'https://picsum.photos/seed/photo2/240/240', url_m: 'https://picsum.photos/seed/photo2/500/500'),
    ExamplePhoto.new(id: '3', title: 'Forest Path', url_sq: 'https://picsum.photos/seed/photo3/75/75', url_q: 'https://picsum.photos/seed/photo3/150/150', url_t: 'https://picsum.photos/seed/photo3/100/100', url_s: 'https://picsum.photos/seed/photo3/240/240', url_m: 'https://picsum.photos/seed/photo3/500/500'),
    ExamplePhoto.new(id: '4', title: 'City Lights', url_sq: 'https://picsum.photos/seed/photo4/75/75', url_q: 'https://picsum.photos/seed/photo4/150/150', url_t: 'https://picsum.photos/seed/photo4/100/100', url_s: 'https://picsum.photos/seed/photo4/240/240', url_m: 'https://picsum.photos/seed/photo4/500/500'),
    ExamplePhoto.new(id: '5', title: 'Desert Dunes', url_sq: 'https://picsum.photos/seed/photo5/75/75', url_q: 'https://picsum.photos/seed/photo5/150/150', url_t: 'https://picsum.photos/seed/photo5/100/100', url_s: 'https://picsum.photos/seed/photo5/240/240', url_m: 'https://picsum.photos/seed/photo5/500/500'),
    ExamplePhoto.new(id: '6', title: 'Autumn Leaves', url_sq: 'https://picsum.photos/seed/photo6/75/75', url_q: 'https://picsum.photos/seed/photo6/150/150', url_t: 'https://picsum.photos/seed/photo6/100/100', url_s: 'https://picsum.photos/seed/photo6/240/240', url_m: 'https://picsum.photos/seed/photo6/500/500'),
    ExamplePhoto.new(id: '7', title: 'Snowy Peaks', url_sq: 'https://picsum.photos/seed/photo7/75/75', url_q: 'https://picsum.photos/seed/photo7/150/150', url_t: 'https://picsum.photos/seed/photo7/100/100', url_s: 'https://picsum.photos/seed/photo7/240/240', url_m: 'https://picsum.photos/seed/photo7/500/500'),
    ExamplePhoto.new(id: '8', title: 'Sunset Beach', url_sq: 'https://picsum.photos/seed/photo8/75/75', url_q: 'https://picsum.photos/seed/photo8/150/150', url_t: 'https://picsum.photos/seed/photo8/100/100', url_s: 'https://picsum.photos/seed/photo8/240/240', url_m: 'https://picsum.photos/seed/photo8/500/500'),
    ExamplePhoto.new(id: '9', title: 'River Valley', url_sq: 'https://picsum.photos/seed/photo9/75/75', url_q: 'https://picsum.photos/seed/photo9/150/150', url_t: 'https://picsum.photos/seed/photo9/100/100', url_s: 'https://picsum.photos/seed/photo9/240/240', url_m: 'https://picsum.photos/seed/photo9/500/500'),
    ExamplePhoto.new(id: '10', title: 'Night Sky', url_sq: 'https://picsum.photos/seed/photo10/75/75', url_q: 'https://picsum.photos/seed/photo10/150/150', url_t: 'https://picsum.photos/seed/photo10/100/100', url_s: 'https://picsum.photos/seed/photo10/240/240', url_m: 'https://picsum.photos/seed/photo10/500/500'),
    ExamplePhoto.new(id: '11', title: 'Green Meadow', url_sq: 'https://picsum.photos/seed/photo11/75/75', url_q: 'https://picsum.photos/seed/photo11/150/150', url_t: 'https://picsum.photos/seed/photo11/100/100', url_s: 'https://picsum.photos/seed/photo11/240/240', url_m: 'https://picsum.photos/seed/photo11/500/500'),
    ExamplePhoto.new(id: '12', title: 'Rocky Shore', url_sq: 'https://picsum.photos/seed/photo12/75/75', url_q: 'https://picsum.photos/seed/photo12/150/150', url_t: 'https://picsum.photos/seed/photo12/100/100', url_s: 'https://picsum.photos/seed/photo12/240/240', url_m: 'https://picsum.photos/seed/photo12/500/500'),
    ExamplePhoto.new(id: '13', title: 'Misty Forest', url_sq: 'https://picsum.photos/seed/photo13/75/75', url_q: 'https://picsum.photos/seed/photo13/150/150', url_t: 'https://picsum.photos/seed/photo13/100/100', url_s: 'https://picsum.photos/seed/photo13/240/240', url_m: 'https://picsum.photos/seed/photo13/500/500'),
    ExamplePhoto.new(id: '14', title: 'Golden Fields', url_sq: 'https://picsum.photos/seed/photo14/75/75', url_q: 'https://picsum.photos/seed/photo14/150/150', url_t: 'https://picsum.photos/seed/photo14/100/100', url_s: 'https://picsum.photos/seed/photo14/240/240', url_m: 'https://picsum.photos/seed/photo14/500/500'),
    ExamplePhoto.new(id: '15', title: 'Waterfall', url_sq: 'https://picsum.photos/seed/photo15/75/75', url_q: 'https://picsum.photos/seed/photo15/150/150', url_t: 'https://picsum.photos/seed/photo15/100/100', url_s: 'https://picsum.photos/seed/photo15/240/240', url_m: 'https://picsum.photos/seed/photo15/500/500'),
    ExamplePhoto.new(id: '16', title: 'Canyon View', url_sq: 'https://picsum.photos/seed/photo16/75/75', url_q: 'https://picsum.photos/seed/photo16/150/150', url_t: 'https://picsum.photos/seed/photo16/100/100', url_s: 'https://picsum.photos/seed/photo16/240/240', url_m: 'https://picsum.photos/seed/photo16/500/500'),
  ].freeze

  FlickrPhoto = Struct.new(:id, :title, :url_sq, :url_q, :url_t, :url_s, :url_m, :owner, keyword_init: true)

  def photos
    return EXAMPLE_PHOTOS.first(photo_count.to_i) if show_example_content
    return [] if flickr_user_id.blank?

    begin
      user_id = resolve_user_id(flickr_user_id)
      return [] unless user_id

      fetch_photos(user_id)
    rescue => e
      Rails.logger.error "Flickr sidebar error: #{e.message}"
      []
    end
  end

  def photo_url(photo)
    case photo_size
    when 'large_square'
      photo.url_q
    when 'thumbnail'
      photo.url_t
    when 'small'
      photo.url_s
    when 'medium'
      photo.url_m
    else
      photo.url_sq
    end
  end

  def photo_link(photo)
    return '#' if show_example_content
    owner = photo.respond_to?(:owner) ? photo.owner : flickr_user_id
    "https://www.flickr.com/photos/#{owner}/#{photo.id}"
  end

  private

  def flickr_api_call(method, params = {})
    base_url = "https://www.flickr.com/services/rest/"
    params = params.merge(
      method: method,
      api_key: FLICKR_KEY,
      format: 'json',
      nojsoncallback: '1'
    )

    query = params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&')
    uri = URI("#{base_url}?#{query}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10

    response = http.get(uri.request_uri)
    JSON.parse(response.body)
  end

  def resolve_user_id(input)
    # If it looks like a user ID (contains @), use it directly
    return input if input.include?('@')

    # If it looks like a URL, use URL lookup
    if input.include?('flickr.com')
      url = input.start_with?('http') ? input : "https://#{input}"
      result = flickr_api_call('flickr.urls.lookupUser', url: url)
      if result['stat'] == 'ok' && result['user']
        return result['user']['id']
      end
    end

    # Try to look up by URL path (e.g., "thomashastings" -> flickr.com/photos/thomashastings)
    result = flickr_api_call('flickr.urls.lookupUser', url: "https://www.flickr.com/photos/#{input}")
    if result['stat'] == 'ok' && result['user']
      return result['user']['id']
    end

    # Fall back to username lookup
    result = flickr_api_call('flickr.people.findByUsername', username: input)
    if result['stat'] == 'ok' && result['user']
      return result['user']['id']
    end

    # Try as NSID directly
    result = flickr_api_call('flickr.people.getInfo', user_id: input)
    if result['stat'] == 'ok' && result['person']
      result['person']['id']
    else
      nil
    end
  end

  def fetch_photos(user_id)
    result = flickr_api_call('flickr.people.getPublicPhotos',
      user_id: user_id,
      per_page: photo_count.to_i,
      extras: 'url_sq,url_q,url_t,url_s,url_m'
    )

    return [] unless result['stat'] == 'ok' && result['photos']

    result['photos']['photo'].map do |p|
      FlickrPhoto.new(
        id: p['id'],
        title: p['title'],
        url_sq: p['url_sq'],
        url_q: p['url_q'],
        url_t: p['url_t'],
        url_s: p['url_s'],
        url_m: p['url_m'],
        owner: p['owner']
      )
    end
  end
end
