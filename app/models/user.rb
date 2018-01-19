class User < ApplicationRecord
  CUSTOMER_OR_SHIPPER = [2, 4]

  attr_accessor :remember_token, :activation_token, :reset_token
  before_save   :downcase_email
  before_create :create_activation_digest
  has_many :comments
  has_many :orders
  has_many :foods
  has_many :customer, through: :active_relationships, source: :customer
  has_many :shippers, through: :active_relationships, source: :employee

  has_many :active_relationships, class_name: "Order",foreign_key: "customer_id"
  has_many :passive_relationships, class_name: "Order",foreign_key: "employee_id"
  has_many :carts
  has_many :votes

  has_secure_password
  validates :name ,presence: true, length: {maximum: 30}
  validates :username, presence: true, length: {minimum: 6}
  validates :password, presence: true, length: {minimum: 8}, allow_blank: true
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, length: {maximum: 255}, format: {with: VALID_EMAIL_REGEX}, allow_blank: true

  scope :hotchef, -> {
    where(user_type: Settings.user_type.chef).joins(:foods).group(:id).order("SUM(rating_avg) DESC").limit(4)
  }

  scope :chef, -> {
    where(user_type: Settings.user_type.chef)
  }

  scope :shipper, -> {
    where(user_type: Settings.user_type.shipper)
  }

  class << self
    def digest string
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end

    def new_token
      SecureRandom.urlsafe_base64
    end

    def auth_facebook user_id, name
      @user = User.find_or_create_by(username: user_id) do |usr|
        usr.name = name
        usr.username = user_id
        pass_digest = User.digest(user_id + name)
        usr.user_type = Settings.user_type.customer
        usr.avatar_url = "https://jsns.eu/components/com_jsn/assets/img/default.jpg"
        usr.password = pass_digest
      end
      @user
    end
  end

  def remember
    self.remember_token = User.new_token
    update_attributes(:remember_digest, User.digest(remember_token))
  end

  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_attributes remember_digest: nil
  end

  def activate
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    update_columns(reset_digest:  User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  def chef?
    self.user_type == Settings.user_type.chef
  end

  def shipper?
    self.user_type == Settings.user_type.shipper
  end

  def admin?
    self.user_type == Settings.user_type.admin
  end

  def customer?
    self.user_type == Settings.user_type.customer
  end

  private

  def downcase_email
    return unless email
    self.email = email.downcase
  end

  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
