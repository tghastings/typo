# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Trigger, type: :model do
  before do
    create(:blog)
  end

  describe '.fire' do
    it 'returns true' do
      expect(Trigger.fire).to be true
    end

    it 'destroys triggers past due date' do
      article = create(:article)
      Trigger.create!(due_at: 1.hour.ago, pending_item: article, trigger_method: 'publish!')
      expect { Trigger.fire }.to change(Trigger, :count).by(-1)
    end
  end

  describe '.post_action' do
    it 'creates a trigger' do
      article = create(:article)
      expect do
        Trigger.post_action(1.hour.from_now, article, 'publish!')
      end.to change(Trigger, :count).by(1)
    end
  end

  describe '.remove' do
    it 'calls delete_all on matching triggers' do
      article = create(:article)
      # Create trigger with matching pending_item_type
      trigger = Trigger.create!(
        due_at: 1.hour.from_now,
        pending_item_id: article.id,
        pending_item_type: 'Article',
        trigger_method: 'publish!'
      )
      Trigger.remove(article)
      expect(Trigger.find_by(id: trigger.id)).to be_nil
    end

    it 'does nothing for new records' do
      article = Article.new
      expect { Trigger.remove(article) }.not_to change(Trigger, :count)
    end
  end

  describe '#trigger_pending_item' do
    it 'calls method on pending item' do
      article = create(:article)
      allow(article).to receive(:publish!)
      trigger = Trigger.create!(due_at: Time.now, pending_item: article, trigger_method: 'publish!')
      trigger.trigger_pending_item
      expect(article).to have_received(:publish!)
    end
  end
end
