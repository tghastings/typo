# coding: utf-8
require 'net/http'
require 'json'

class CodStatsSidebar < Sidebar
  display_name "Call of Duty Stats"
  description "Display your Call of Duty stats from COD Tracker"

  setting :title, 'CoD Stats'
  setting :tracker_api_key, '', :label => 'Tracker.gg API Key'
  setting :platform, 'battlenet', :label => 'Platform', :choices => [
    ['battlenet', 'Battle.net'],
    ['psn', 'PlayStation'],
    ['xbl', 'Xbox Live'],
    ['atvi', 'Activision ID']
  ]
  setting :username, '', :label => 'Username (URL encoded, e.g., Player%231234)'
  setting :game, 'mw2', :label => 'Game', :choices => [
    ['mw2', 'Modern Warfare II'],
    ['wz2', 'Warzone 2.0'],
    ['mw3', 'Modern Warfare III'],
    ['wz3', 'Warzone 3']
  ]
  setting :show_example_content, false, :label => 'Show example content (for preview)', :input_type => :checkbox

  # Example data for preview
  EXAMPLE_STATS = {
    'platformInfo' => {
      'platformUserHandle' => 'ExamplePlayer#1234',
      'avatarUrl' => 'https://picsum.photos/seed/avatar/64/64'
    },
    'segments' => [
      {
        'type' => 'overview',
        'stats' => {
          'kills' => { 'value' => 15420, 'displayValue' => '15,420' },
          'deaths' => { 'value' => 12350, 'displayValue' => '12,350' },
          'kdRatio' => { 'value' => 1.25, 'displayValue' => '1.25' },
          'wins' => { 'value' => 342, 'displayValue' => '342' },
          'losses' => { 'value' => 298, 'displayValue' => '298' },
          'wlRatio' => { 'value' => 1.15, 'displayValue' => '1.15' },
          'timePlayed' => { 'value' => 432000, 'displayValue' => '5d 0h 0m' },
          'headshots' => { 'value' => 4250, 'displayValue' => '4,250' },
          'accuracy' => { 'value' => 0.223, 'displayValue' => '22.3%' }
        }
      }
    ]
  }.freeze

  def configured?
    tracker_api_key.present? && username.present?
  end

  def stats
    return EXAMPLE_STATS if show_example_content
    return nil unless configured?

    # COD Tracker API endpoint
    uri = URI("https://api.tracker.gg/api/v2/cod/standard/profile/#{platform}/#{username}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    request['TRN-Api-Key'] = tracker_api_key
    request['Accept'] = 'application/json'

    response = http.request(request)
    return nil unless response.code == '200'

    data = JSON.parse(response.body)
    data['data']
  rescue => e
    Rails.logger.error "COD Stats error: #{e.message}"
    nil
  end

  def format_stat(value)
    return '—' if value.nil?
    if value >= 1_000_000
      "#{(value / 1_000_000.0).round(1)}M"
    elsif value >= 1_000
      "#{(value / 1_000.0).round(1)}K"
    else
      value.to_s
    end
  end
end
