class CartsController < ApplicationController
  before_action :authenticate_user!

  def show
    @cart = current_cart
    @items = @cart.cart_items.includes(:course)
  end
end
