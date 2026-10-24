class RecurringItemsController < ApplicationController
  before_action :set_item, only: %i[ edit update destroy ]

  def index
    @items = RecurringItem.order(:name)
  end

  def new
    @item = RecurringItem.new(frequency: "monthly", treatment: "additional", starts_on: Date.current)
  end

  def create
    @item = RecurringItem.new(item_params)
    if @item.save
      redirect_to recurring_items_path, notice: "Recurring item saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @item.update(item_params)
      redirect_to recurring_items_path, notice: "Recurring item updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy
    redirect_to recurring_items_path, notice: "Recurring item removed."
  end

  private
    def set_item
      @item = RecurringItem.find(params[:id])
    end

    def item_params
      params.require(:recurring_item).permit(:name, :direction, :amount, :frequency, :starts_on, :ends_on, :treatment)
    end
end
