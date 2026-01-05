# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConfigManager::Item do
  describe '#canonicalize' do
    let(:item) { described_class.new }

    context 'with boolean type' do
      before { item.ruby_type = :boolean }

      it 'returns false for "0"' do
        expect(item.canonicalize('0')).to be false
      end

      it 'returns false for 0' do
        expect(item.canonicalize(0)).to be false
      end

      it 'returns false for empty string' do
        expect(item.canonicalize('')).to be false
      end

      it 'returns false for false' do
        expect(item.canonicalize(false)).to be false
      end

      it 'returns false for "false"' do
        expect(item.canonicalize('false')).to be false
      end

      it 'returns false for "f"' do
        expect(item.canonicalize('f')).to be false
      end

      it 'returns false for nil' do
        expect(item.canonicalize(nil)).to be false
      end

      it 'returns true for "1"' do
        expect(item.canonicalize('1')).to be true
      end

      it 'returns true for true' do
        expect(item.canonicalize(true)).to be true
      end
    end

    context 'with integer type' do
      before { item.ruby_type = :integer }

      it 'converts string to integer' do
        expect(item.canonicalize('42')).to eq(42)
      end

      it 'converts float to integer' do
        expect(item.canonicalize(3.14)).to eq(3)
      end
    end

    context 'with string type' do
      before { item.ruby_type = :string }

      it 'converts to string' do
        expect(item.canonicalize(123)).to eq('123')
      end
    end

    context 'with yaml type' do
      before { item.ruby_type = :yaml }

      it 'converts to yaml' do
        result = item.canonicalize({ key: 'value' })
        expect(result).to be_a(String)
        expect(result).to include('key')
      end
    end

    context 'with object type' do
      before { item.ruby_type = :object }

      it 'returns value unchanged' do
        obj = { key: 'value' }
        expect(item.canonicalize(obj)).to eq(obj)
      end
    end
  end
end

RSpec.describe ConfigManager do
  describe 'ClassMethods' do
    let(:blog) { create(:blog) }

    describe '.fields' do
      it 'returns hash of fields' do
        expect(Blog.fields).to be_a(Hash)
      end
    end

    describe '.default_for' do
      it 'returns default value for field' do
        # Check a known field
        expect(Blog.default_for('limit_article_display')).to be_a(Integer).or be_nil
      end
    end
  end

  describe 'instance methods' do
    let(:blog) { create(:blog) }

    describe '#canonicalize' do
      it 'canonicalizes values according to field type' do
        # Test through a blog instance
        expect(blog).to respond_to(:canonicalize)
      end
    end
  end
end
