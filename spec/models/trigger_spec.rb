# frozen_string_literal: true

require 'spec_helper'

describe 'With the contents fixture' do
  before(:each) do
    Factory(:blog)
    @page = Factory(:page)
  end

  it '.post_action should not fire immediately for future triggers' do
    expect do
      Trigger.post_action(Time.now + 2, @page, 'publish!')
      expect(Trigger.count).to eq(1)
      Trigger.fire
      expect(Trigger.count).to eq(1)
    end.not_to raise_error

    # Stub Time.now to emulate sleep.
    t = Time.now
    allow(Time).to receive(:now).and_return(t + 5.seconds)

    # After time passes, the trigger should fire and call publish! on the page
    expect_any_instance_of(Page).to receive(:publish!)
    Trigger.fire
    expect(Trigger.count).to eq(0)
  end

  it '.post_action should fire immediately if the target time is <= now' do
    expect_any_instance_of(Page).to receive(:publish!)
    Trigger.post_action(Time.now, @page, 'publish!')
    expect(Trigger.count).to eq(0)
  end
end
