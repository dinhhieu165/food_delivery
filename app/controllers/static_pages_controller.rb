class StaticPagesController < ApplicationController
  def home
    if params[:search]
      @foods = Food.search params[:search]
      if !@foods.present?
        flash[:warning] = t("views.static_pages.search.nomatch")
        redirect_to root_url
      else
        render "show_all_foods"
        return
      end
    end

    @all_orders = Order.all.paginate page: params[:page]
    @new_foods = Food.newfood
    @hot_foods = Food.hotfood
    @users = User.all
    @hot_chefs = User.hotchef
    @shippers = User.shipper
    @all_foods = Food.all.paginate page: params[:page], per_page: 18

    respond_to do |format|
      format.html
      format.js
    end
  end
end
