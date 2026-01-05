# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Redirect, type: :model do
  before do
    create(:blog)
  end

  describe 'factory' do
    it 'creates valid redirect' do
      redirect = create(:redirect)
      expect(redirect).to be_valid
    end
  end

  describe 'attributes' do
    it 'has from_path' do
      redirect = create(:redirect, from_path: 'old/path')
      expect(redirect.from_path).to eq('old/path')
    end

    it 'has to_path' do
      redirect = create(:redirect, to_path: '/new/path')
      expect(redirect.to_path).to eq('/new/path')
    end
  end
end
