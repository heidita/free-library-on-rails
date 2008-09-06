class ItemsController < ApplicationController
	before_filter :login_required, :only => [ :new, :create, :destroy, :edit, :update ]

	def itemclass; Item end

	def index
		@items = region.items.find(:all, :conditions => { :type => itemclass.to_s })
	end

	def show
		@item = itemclass.find(params[:id])
	rescue ActiveRecord::RecordNotFound
		four_oh_four
	end

	def new
		@item = itemclass.new(params[:item])

		@tags = params[:tags]
		@tags ||= []
	end

	def create
		@item = itemclass.new(params[:item])

		@item.created = Time.now
		@item.owner = self.current_user

		@item.save!

		@item.tag_with params[:tags] if params[:tags]

		redirect_to :controller => itemclass.to_s.tableize, :action => 'show', :id => @item
	end

	def edit
		@item = itemclass.find(params[:id])

		unless @item.owned_by? self.current_user
			redirect_to polymorphic_path(@item)
		end
	rescue ActiveRecord::RecordNotFound
		four_oh_four
	end

	def update
		@item = itemclass.find(params[:id])

		unless @item.owned_by? self.current_user
			unauthorized 'not authorized to edit this item'; return
		end

		itemclass.update(params[:id], params[:item])

		@item.tag_with params[:tags]

		redirect_to polymorphic_path(@item)
	end

	def destroy
		@item = Item.find(params[:id])

		unless @item.owned_by? self.current_user
			unauthorized 'not authorized to edit this item'; return
		end

		@item.destroy

		# XXX this has behaved weird anecdotally... come back to it and test
		redirect_to user_path(self.current_user.login)
	end

	def search
		@query = params[:q]

		q = "%#{@query}%"

		@title_results = Item.find :all, :conditions => [ 'title LIKE ?', q ]
		@author_results = Item.find :all, :conditions => [ 'author_first LIKE ? OR author_last LIKE ?', q, q ]
		@description_results = Item.find :all, :conditions => [ 'description LIKE ?', q ]
	end
end
