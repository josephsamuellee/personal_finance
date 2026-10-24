class SavingsGoalsController < ApplicationController
  before_action :set_goal, only: %i[ edit update ]

  def index
    @goals = SavingsGoal.order(starts_on: :desc)
  end

  def new
    @goal = SavingsGoal.new(starts_on: Date.current)
  end

  def create
    @goal = SavingsGoal.new(goal_params)
    if @goal.save
      redirect_to savings_goals_path, notice: "Savings target saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @goal.update(goal_params)
      redirect_to savings_goals_path, notice: "Savings target updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_goal
      @goal = SavingsGoal.find(params[:id])
    end

    def goal_params
      params.require(:savings_goal).permit(:amount, :starts_on, :ends_on, :reason, :review_on)
    end
end
