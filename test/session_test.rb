require File.dirname(__FILE__) + '/test_helper.rb'

class SessionTest < ActiveSupport::TestCase
  setup :setup_http_stubs, :setup_users

  def setup_http_stubs
    stub_request(:post, "http://example:bogus@localhost/crowd/console?username=ben").
      with(:body => "<password><value>benrocks</value></password>", 
           :headers => {'Accept'=>'*/*', 'Content-Type'=>'text/xml'}).
      to_return(:status => 200, :body => %q[<?xml version="1.0" encoding="UTF-8" standalone="yes"?><user name="ben" expand="attributes"><link rel="self" href="http://localhost/crowd/rest/usermanagement/latest/user?username=ben"/><first-name>Ben</first-name><last-name>Johnson</last-name><display-name>Rob Dimarco</display-name><email>ben@foo.com</email><password><link rel="edit" href="http://localhost/crowd/rest/usermanagement/latest/user/password?username=ben"/></password><active>true</active><attributes><link rel="self" href="http://localhost/crowd/rest/usermanagement/latest/user/attribute?username=ben"/></attributes></user>], :headers => {})
    
    stub_request(:post, "http://example:bogus@localhost/crowd/console?username=ben").
      with(:body => "<password><value>bogus</value></password>", 
           :headers => {'Accept'=>'*/*', 'Content-Type'=>'text/xml'}).
      to_return(:status => 400, :body => %q[Incorrect], :headers => {})
  end
  
  def setup_users
    User.find_or_create_by_login :login=>"ben", :email=>"foo@bar.com", :password=>"benrocks", :password_confirmation => "benrocks"
  end
  
  def test_use_crowd_rest_authentication
    assert_not_nil User.find_by_login 'ben'

    UserSession.crowd_base_url = "http://localhost/crowd/console"
    UserSession.crowd_application_name = "example"
    UserSession.crowd_application_password = "bogus"
    
    session = UserSession.new(:login => 'ben', :password => "benrocks")

    assert session.save
  end

  def test_invalid_password
    assert_not_nil User.find_by_login 'ben'
    UserSession.crowd_base_url = "http://localhost/crowd/console"
    UserSession.crowd_application_name = "example"
    UserSession.crowd_application_password = "bogus"
    
    session = UserSession.new(:login => 'ben', :password => "bogus")

    assert !session.save
    assert_equal ["Password is not valid"], session.errors.full_messages
  end
end
