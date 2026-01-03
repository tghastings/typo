# coding: utf-8
require 'net/http'
require 'json'
require 'base64'

class SpotifySidebar < Sidebar
  display_name "Spotify"
  description "Display your recently played tracks or now playing from Spotify"

  setting :title, 'Now Playing'
  setting :client_id, '', :label => 'Spotify Client ID'
  setting :client_secret, '', :label => 'Spotify Client Secret'
  setting :refresh_token, '', :label => 'Spotify Refresh Token'
  setting :display_count, '5', :label => 'Number of tracks to show'
  setting :show_example_content, false, :label => 'Show example content (for preview)', :input_type => :checkbox

  # Example data for preview
  EXAMPLE_NOW_PLAYING = {
    'is_playing' => true,
    'item' => {
      'name' => 'Bohemian Rhapsody',
      'artists' => [{ 'name' => 'Queen' }],
      'album' => {
        'name' => 'A Night at the Opera',
        'images' => [
          { 'url' => 'https://picsum.photos/seed/album1/64/64' }
        ]
      },
      'external_urls' => { 'spotify' => '#' }
    }
  }.freeze

  EXAMPLE_RECENTLY_PLAYED = [
    {
      'track' => {
        'name' => 'Stairway to Heaven',
        'artists' => [{ 'name' => 'Led Zeppelin' }],
        'album' => { 'images' => [{ 'url' => 'https://picsum.photos/seed/album2/64/64' }] },
        'external_urls' => { 'spotify' => '#' }
      }
    },
    {
      'track' => {
        'name' => 'Hotel California',
        'artists' => [{ 'name' => 'Eagles' }],
        'album' => { 'images' => [{ 'url' => 'https://picsum.photos/seed/album3/64/64' }] },
        'external_urls' => { 'spotify' => '#' }
      }
    },
    {
      'track' => {
        'name' => 'Sweet Child O\' Mine',
        'artists' => [{ 'name' => 'Guns N\' Roses' }],
        'album' => { 'images' => [{ 'url' => 'https://picsum.photos/seed/album4/64/64' }] },
        'external_urls' => { 'spotify' => '#' }
      }
    },
    {
      'track' => {
        'name' => 'Comfortably Numb',
        'artists' => [{ 'name' => 'Pink Floyd' }],
        'album' => { 'images' => [{ 'url' => 'https://picsum.photos/seed/album5/64/64' }] },
        'external_urls' => { 'spotify' => '#' }
      }
    },
    {
      'track' => {
        'name' => 'Back in Black',
        'artists' => [{ 'name' => 'AC/DC' }],
        'album' => { 'images' => [{ 'url' => 'https://picsum.photos/seed/album6/64/64' }] },
        'external_urls' => { 'spotify' => '#' }
      }
    }
  ].freeze

  def configured?
    client_id.present? && client_secret.present? && refresh_token.present?
  end

  def access_token
    return @access_token if @access_token

    uri = URI('https://accounts.spotify.com/api/token')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}"
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.body = "grant_type=refresh_token&refresh_token=#{refresh_token}"

    response = http.request(request)
    data = JSON.parse(response.body)
    @access_token = data['access_token']
  rescue => e
    Rails.logger.error "Spotify token error: #{e.message}"
    nil
  end

  def now_playing
    return EXAMPLE_NOW_PLAYING if show_example_content
    return nil unless configured?

    uri = URI('https://api.spotify.com/v1/me/player/currently-playing')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_token}"

    response = http.request(request)
    return nil if response.code == '204' || response.body.blank?

    JSON.parse(response.body)
  rescue => e
    Rails.logger.error "Spotify now playing error: #{e.message}"
    nil
  end

  def recently_played
    return EXAMPLE_RECENTLY_PLAYED.first(display_count.to_i) if show_example_content
    return [] unless configured?

    uri = URI("https://api.spotify.com/v1/me/player/recently-played?limit=#{display_count}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_token}"

    response = http.request(request)
    data = JSON.parse(response.body)
    data['items'] || []
  rescue => e
    Rails.logger.error "Spotify recently played error: #{e.message}"
    []
  end
end
