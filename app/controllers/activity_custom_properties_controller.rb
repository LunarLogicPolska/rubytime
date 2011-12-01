class ActivityCustomPropertiesController < ApplicationController
  
  respond_to :html

  before_filter :ensure_admin
  before_filter :load_activity_custom_property, :only => [:edit, :update, :destroy]

  def index
    @new_activity_custom_property = ActivityCustomProperty.new
    @activity_custom_properties = ActivityCustomProperty.all
    respond_with @activity_custom_properties  
  end
  
  def create
    @new_activity_custom_property = ActivityCustomProperty.new(params[:activity_custom_property])
    if @new_activity_custom_property.save
      redirect_to activity_custom_properties_path, :message => 
        {:notice => "Custom property was successfully created"}
    else
      @activity_custom_properties = ActivityCustomProperty.all
      render :index
    end
  end
  
  def edit
    respond_with @activity_custom_property
  end
  
  def update
    if @activity_custom_property.update(params[:activity_custom_property])
      redirect_to activity_custom_properties_path, :message => 
        {:notice => "Custom property was successfully created"}
    else
      render :edit
    end
  end
  
  def destroy
    if @activity_custom_property.destroy
      redirect_to activity_custom_properties_path, :message => 
        {:notice => "Custom property was successfully deleted"}
    else
      redirect_to activity_custom_properties_path, :message => 
        {:error => "Unable to delete"}
    end
  end
  
  protected
  
  def load_activity_custom_property
    not_found and return unless @activity_custom_property = ActivityCustomProperty.get(params[:id])
  end
  
  def number_of_columns
    ["edit", "update"].include?(params[:action]) ? 1 : super
  end

end