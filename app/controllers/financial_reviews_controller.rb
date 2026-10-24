class FinancialReviewsController < ApplicationController
  def index
    @reviews = FinancialReview.order(review_on: :desc)
    @decisions = FinancialDecision.order(decided_on: :desc)
  end

  def show
    @review = FinancialReview.find(params[:id])
  end

  def new
    @review = FinancialReview.new(review_on: Date.current)
  end

  def create
    @review = FinancialReview.new(review_params)
    @review.created_by = current_user
    if @review.save
      redirect_to review_path(@review), notice: "Review saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def review_params
      params.require(:financial_review).permit(:review_on, :commentary)
    end
end
