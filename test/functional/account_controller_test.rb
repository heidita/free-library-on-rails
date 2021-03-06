require File.dirname(__FILE__) + '/../test_helper'

class AccountControllerTest < ActionController::TestCase
	include AuthenticatedTestHelper

	def setup
		@controller = AccountController.new
		@request    = ActionController::TestRequest.new
		@response   = ActionController::TestResponse.new
	end

	def test_routing
		assert_routing 'account', :controller => 'account', :action => 'index'
		assert_routing 'account/signup', :controller => 'account', :action => 'signup'
		assert_routing 'account/login', :controller => 'account', :action => 'login'
	end

	def test_show_unauthenticated
		get :index

		assert_response 302
	end

	def test_show
		login_as 'bct'
		get :index

		assert_response :success
	end

	def test_signup
		get :signup

		assert_response :success
	end

	def test_login
		get :signup

		assert_response :success
	end

	def test_update
		login_as 'bct'

		assert_difference(User, :count, 0) do
		  post :update, :user => { :cellphone => '7807086602', :email => 'new-bct@example.org' }
		end

		assert_response 302

		bct = User.find_by_login('bct')
		assert_equal '7807086602', bct.cellphone
		assert_equal 'new-bct@example.org', bct.email
	end

	def test_update_password_no_confirm
		login_as 'bct'

		bct = User.find_by_login('bct')
		orig = bct.crypted_password

		assert_difference(User, :count, 0) do
		  post :update, :user => { :password => 'test' }
		end

		assert_response 302
		assert @response.flash[:error]

		# password was not updated
		bct = User.find_by_login('bct')
		assert_equal orig, bct.crypted_password
	end

	def test_update_password_bad_confirm
		login_as 'bct'

		bct = User.find_by_login('bct')
		orig = bct.crypted_password

		assert_difference(User, :count, 0) do
		  post :update, :user => { :password => 'test', :password_confirmation => 'oops' }
		end

		assert_response 302
		assert @response.flash[:error]

		# password was not updated
		bct = User.find_by_login('bct')
		assert_equal orig, bct.crypted_password
	end

	def test_update_password
		# correct confirmation included
		login_as 'bct'

		bct = User.find_by_login('bct')
		orig = bct.crypted_password

		assert_difference(User, :count, 0) do
		  post :update, :user => { :password => 'test', :password_confirmation => 'test' }
		end

		assert_response 302
		assert @response.flash[:notice]

		bct = User.find_by_login('bct')
		assert bct.authenticated?('test')
	end

	def test_update_unauthenticated
		post :update, :user => { :cellphone => '7807086602' }

		assert_response 302
	end

	# try to change attributes that shouldn't be changeable
	def test_update_protected_attributes
		login_as 'bct'

		old_user = User.find_by_login('bct')

		post :update, :user => { :id                        => 1337,
								 :created_at                => '2008-04-20',
								 :updated_at                => '2008-04-20',
								 :activated_at              => '2008-04-20',
								 :login                     => 'somebody-else'
							  }

		# the update should succeed but nothing should change
		assert_response 302

		bct = User.find_by_login('bct')

		assert_not_nil bct, 'user was able to rename themself'
		assert_equal old_user.id, bct.id
		assert_equal 'bct', bct.login
		assert_equal Time.parse('2008-04-01'), bct.created_at
		assert_equal Time.parse('2008-04-01'), bct.activated_at

		assert((Time.now - bct.updated_at).abs < 5)
	end

	def test_tag
		login_as 'bct'

		assert_difference(User, :count, 0) do
		  post :update, :tags => 'funny hats, celery'
		end

		assert_response 302
		assert @response.flash[:notice]

		bct = User.find_by_login('bct')
		assert bct.tags.member?('funny hats')
		assert bct.tags.member?('celery')
	end

	def test_reset_password
		get :reset_password

		assert_response 200

		bct = User.find_by_login 'bct'
		old_passwd = bct.crypted_password

		post :reset_password, :email => bct.email
		assert_redirected_to :controller => 'account', :action => 'login'
		assert @response.flash[:notice], 'Notice was not given to the user.'

		bct = User.find_by_login 'bct'
		assert_not_equal old_passwd, bct.crypted_password
	end

	def test_reset_password_bad_email
		post :reset_password, :email => 'some-email-that@doesnt-exist.example'

		assert_redirected_to :controller => 'account', :action => 'login'
		assert @response.flash[:error], 'User was not notified of error.'
	end
end
