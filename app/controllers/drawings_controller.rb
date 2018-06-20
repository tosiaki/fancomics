class DrawingsController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]
  before_action :check_user, only: [:edit, :update, :destroy]

  def new
    @drawing = Drawing.new
  end

  def create
    @drawing = current_user.drawings.build(drawing_params);
    @drawing.fandom_list.add(tagging_params[:fandom_list], parse: true ) unless tagging_params[:fandom_list].empty?
    @drawing.character_list.add(tagging_params[:character_list], parse: true ) unless tagging_params[:character_list].empty?
    @drawing.relationship_list.add(tagging_params[:relationship_list], parse: true ) unless tagging_params[:relationship_list].empty?
    @drawing.tag_list.add(tagging_params[:tag_list], parse: true ) unless tagging_params[:tag_list].empty?
    if @drawing.save
      flash[:success] = "Drawing posted!"
      redirect_to @drawing
    else
      render 'drawings/new'
    end
  end
  
  def show
    @drawing = Drawing.find(params[:id])
  end

  def index
    if params[:tags]
      tag_list = params[:tags].split(",").map(&:strip)
      @drawings = Drawing.tagged_with(tag_list)
    else
      @drawings = Drawing.all
    end
  end

  def edit
  end

  def update
    @drawing.assign_attributes(drawing_params)
    update_tags
    if @drawing.save
      flash[:success] = "Details updated!"
      redirect_to @drawing
    else
      render 'edit'
    end
  end

  def destroy
    @drawing.destroy
    flash[:success] = "Fanart deleted."
    redirect_to current_user
  end

  private

    def drawing_params
      params.require(:drawing).permit(:rating, :title, :drawing, :caption)
    end

    def tagging_params
      params.require(:drawing).permit(:fandom_list, :character_list, :relationship_list, :tag_list)
    end

    def update_tags
      contexts = ['fandom', 'relationship', 'character', 'tag']
      contexts.each do |context|
        set_tags(context)
      end
    end

    def set_tags(context)
      list_name = "#{context}_list";
      new_tags = params['drawing'][list_name].split(',').map(&:strip).reject { |c| c.empty? }
      old_tags = @drawing.send(list_name)
      unless new_tags == old_tags
        (old_tags - new_tags).map {|e| @drawing.send(list_name).remove(e)}
        (new_tags - old_tags ).map {|e| @drawing.send(list_name).add e}
      end
    end

    def check_user
      @drawing = current_user.drawings.find(params[:id])
      redirect_to Drawing.find(params[:id]) unless @drawing
    end
end
