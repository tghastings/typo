# Rails 7 Flash Session Hotfix
#
# In Rails 7, ActionDispatch::Flash::RequestMethods#commit_flash calls session.enabled?
# However, in tests and some edge cases, session might be a plain Hash instead of
# a proper session object. This causes "undefined method 'enabled?' for Hash" errors.
#
# This monkeypatch adds the enabled? and loaded? methods to Hash to make it compatible
# with Rails 7's flash handling.

class Hash
  # Returns true if the hash (acting as a session) is enabled
  # In the context of a test session, we always consider it enabled
  def enabled?
    true
  end unless method_defined?(:enabled?)

  # Returns true if the hash (acting as a session) is loaded
  # In the context of a test session, we always consider it loaded
  def loaded?
    true
  end unless method_defined?(:loaded?)
end
