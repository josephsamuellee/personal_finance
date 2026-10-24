class FinancialDecisionsController < ApplicationController
  before_action :set_decision, only: %i[ show edit update ]

  def index
    @decisions = FinancialDecision.order(decided_on: :desc)
  end

  def show
  end

  def new
    @decision = FinancialDecision.new(decided_on: Date.current)
  end

  def create
    @decision = FinancialDecision.new(decision_params)
    @decision.created_by = current_user
    @decision.updated_by = current_user
    if @decision.save
      redirect_to decision_path(@decision), notice: "Decision saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @decision.revision_user = current_user
    @decision.updated_by = current_user
    if @decision.update(decision_params)
      redirect_to decision_path(@decision), notice: "Decision updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_decision
      @decision = FinancialDecision.find(params[:id])
    end

    def decision_params
      params.require(:financial_decision).permit(
        :decided_on, :description, :rationale, :alternatives, :expected_effect, :review_on, :outcome
      )
    end
end
