# frozen_string_literal: true

require 'spec_helper'
require 'net/http'

RSpec.describe Ping, type: :model do
  before do
    create(:blog)
  end

  describe 'associations' do
    it 'belongs to article' do
      article = create(:article)
      ping = Ping.create!(url: 'http://example.com', article: article)
      expect(ping.article).to eq(article)
    end

    it 'allows article to be nil' do
      ping = Ping.new(url: 'http://example.com', article: nil)
      expect(ping.article).to be_nil
    end
  end

  describe '#send_pingback_or_trackback' do
    it 'starts a thread' do
      article = create(:article)
      ping = Ping.create!(url: 'http://example.com', article: article)
      thread = ping.send_pingback_or_trackback('http://example.com/origin')
      expect(thread).to be_a(Thread)
      thread.kill
    end
  end

  describe '#send_weblogupdatesping' do
    it 'starts a thread' do
      article = create(:article)
      ping = Ping.create!(url: 'http://example.com', article: article)
      thread = ping.send_weblogupdatesping('http://server.com', 'http://origin.com')
      expect(thread).to be_a(Thread)
      thread.kill
    end
  end

  describe 'Pinger' do
    let(:article) { create(:article, title: 'Test Article', body: 'Test body content') }
    let(:ping) { Ping.create!(url: 'http://example.com/post', article: article) }

    describe '#pingback_url' do
      it 'extracts pingback URL from X-Pingback header' do
        pinger = Ping::Pinger.send(:new, 'http://origin.com', ping)
        response = double('response', body: '')
        allow(response).to receive(:[]).with('X-Pingback').and_return('http://example.com/pingback')
        allow(pinger).to receive(:response).and_return(response)

        expect(pinger.pingback_url).to eq('http://example.com/pingback')
      end

      it 'extracts pingback URL from link element' do
        pinger = Ping::Pinger.send(:new, 'http://origin.com', ping)
        response = double('response', body: '<link rel="pingback" href="http://example.com/pingback" />')
        allow(response).to receive(:[]).with('X-Pingback').and_return(nil)
        allow(pinger).to receive(:response).and_return(response)

        expect(pinger.pingback_url).to eq('http://example.com/pingback')
      end

      it 'returns nil when no pingback URL found' do
        pinger = Ping::Pinger.send(:new, 'http://origin.com', ping)
        response = double('response', body: '<html></html>')
        allow(response).to receive(:[]).with('X-Pingback').and_return(nil)
        allow(pinger).to receive(:response).and_return(response)

        expect(pinger.pingback_url).to be_nil
      end
    end

    describe '#trackback_url' do
      it 'extracts trackback URL from RDF' do
        rdf_content = <<~RDF
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                   xmlns:dc="http://purl.org/dc/elements/1.1/"
                   xmlns:trackback="http://madskills.com/public/xml/rss/module/trackback/">
            <rdf:Description trackback:ping="http://example.com/trackback/1" dc:identifier="http://example.com/post" />
          </rdf:RDF>
        RDF
        pinger = Ping::Pinger.send(:new, 'http://origin.com', ping)
        response = double('response', body: rdf_content)
        allow(pinger).to receive(:response).and_return(response)

        expect(pinger.trackback_url).to eq('http://example.com/trackback/1')
      end

      it 'falls back to ping URL when no RDF found' do
        pinger = Ping::Pinger.send(:new, 'http://origin.com', ping)
        response = double('response', body: '<html></html>')
        allow(pinger).to receive(:response).and_return(response)

        expect(pinger.trackback_url).to eq('http://example.com/post')
      end
    end

    describe '#article and #blog' do
      it 'has article accessor' do
        pinger = Ping::Pinger.send(:new, 'http://origin.com', ping)
        expect(pinger.article).to eq(article)
      end

      it 'has blog accessor' do
        pinger = Ping::Pinger.send(:new, 'http://origin.com', ping)
        expect(pinger.blog).to eq(article.blog)
      end
    end

    describe '#send_pingback' do
      it 'returns false when no pingback URL' do
        pinger = Ping::Pinger.send(:new, 'http://origin.com', ping)
        allow(pinger).to receive(:pingback_url).and_return(nil)

        expect(pinger.send_pingback).to be false
      end
    end

    describe '#origin_url' do
      it 'returns the origin URL' do
        pinger = Ping::Pinger.send(:new, 'http://origin.com', ping)
        expect(pinger.origin_url).to eq('http://origin.com')
      end
    end

    describe '#ping' do
      it 'returns the ping object' do
        pinger = Ping::Pinger.send(:new, 'http://origin.com', ping)
        expect(pinger.ping).to eq(ping)
      end
    end
  end
end
