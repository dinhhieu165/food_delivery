class UsersController < ApplicationController
  def show
    @user = User.find_by id: params[:id]
    @foods = Food.by_chef @user.id if @user && @user.chef?
    redirect_to root_url unless @user
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new user_params
    if @user.save
      @user.send_activation_email
      flash[:info] = t("controllers.users.register.info")
      redirect_to @user
    else
      render "new"
    end
  end

  def update
    if logged_in? && current_user.admin?
      @user = User.find params[:id]
      if @user.update_attributes(authority_params)
        flash[:success] = t("views.users.update.success")
        redirect_to root_url
      end
    else
      flash[:danger] = t("views.users.update.danger2")
      redirect_to root_url
    end
  end

  private
    def user_params
      params.require(:user).permit :name, :email, :username,
                                   :password, :password_confirmation,
                                   :address, :phone_number
    end

    def authority_params
      params.require(:user).permit :user_type
    end
end
