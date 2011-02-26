require File.dirname(__FILE__) + '/test_helper.rb'

class ActsAsAuthenticTest < ActiveSupport::TestCase
  def test_included
    assert User.send(:acts_as_authentic_modules).include?(AuthlogicCrowdRest::ActsAsAuthentic::Methods)
  end
end
