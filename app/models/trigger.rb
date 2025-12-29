class Trigger < ActiveRecord::Base
  belongs_to :pending_item, optional: true, polymorphic: true

  class << self
    def post_action(due_at, item, method='came_due')
      create!(:due_at => due_at, :pending_item => item,
              :trigger_method => method)
      fire
    end

    def fire
      where('due_at <= ?', Time.now).destroy_all
      true
    end

    def remove(pending_item, conditions = { })
      return if pending_item.new_record?
      scope = where(pending_item_id: pending_item.id, pending_item_type: pending_item.class.to_s)
      scope = scope.where(conditions) if conditions.present?
      scope.delete_all
    end
  end

  before_destroy :trigger_pending_item

  def trigger_pending_item
    pending_item.send(trigger_method) if pending_item
    return true
  end
end
