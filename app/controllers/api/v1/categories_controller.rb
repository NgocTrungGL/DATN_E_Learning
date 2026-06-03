module Api
  module V1
    class CategoriesController < ApplicationController
      def subcategories
        parent = Category.find_by(id: params[:id])
        if parent.nil?
          render json: { error: "Category not found" }, status: :not_found
          return
        end

        subs = parent.subcategories.order(:name)
        render json: {
          data: subs.map { |c| { id: c.id, name: c.name } }
        }
      end
    end
  end
end
