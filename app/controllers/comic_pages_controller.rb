class ComicPagesController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create, :change_orientation, :destroy]
  before_action :check_user, only: [:new, :create, :edit, :update, :change_orientation, :destroy]
  before_action :check_pages, only: :destroy

  def new
    @comic_page = @comic.comic_pages.build
    if params[:page].nil?
      @current_page = @comic.comic_pages.count+1
    else
      @current_page = params[:page]
    end
  end

  def create
    @comic_page = @comic.comic_pages.build(page: params[:comic_page][:page_number], drawing: params[:comic_page][:new_page], orientation: params[:comic_page][:orientation])
    @comic_page.page ||= @comic.comic_pages.count+1
    @comic_page.page = [ @comic_page.page.abs.round, @comic.comic_pages.count+1 ].min
    if @comic_page.valid?
      @comic_page.save
      @comic.comic_pages.each do |page|
        page.increment!(:page) if page.page >= @comic_page.page && page != @comic_page
      end
      new_max_page = @comic.comic_pages.map(&:page).max
      if @comic.pages != 0 && @comic.pages < new_max_page
        @comic.update_attribute(:pages, new_max_page)
      end
      if @comic.max_pages < new_max_page
        @comic.update_attribute(:max_pages, new_max_page)
        @comic.update_attribute(:page_addition, Time.now)
      end
      @comic.touch
      redirect_to comic_path(@comic, anchor: "page-#{@comic_page.page}")
    else
      @current_page = params[:comic_page][:page_number]
      render 'comic_pages/new'
    end
  end

  def edit
    @comic_page = @comic.comic_pages.find_by( page: params[:page].to_i )
  end

  def update
    @comic_page = @comic.comic_pages.find_by( page: params[:page].to_i )
    if @comic_page.update_attribute(:drawing, params[:comic_page][:new_page] )
      flash[:success] = "Updated page"
    end
    redirect_to comic_path(@comic, anchor: "page-#{@comic_page.page}")
  end

  def change_orientation
    @comic_page = @comic.comic_pages.find_by( page: params[:page].to_i )
    if @comic_page.update_attribute(:orientation, params[:orientation])
      flash[:success] = "Changed page orientation"
    end
    redirect_to comic_path(@comic, anchor: "page-#{@comic_page.page}")
  end

  def destroy
    @comic_page = @comic.comic_pages.find_by( page: params[:page].to_i )
    @comic_page.destroy
    @comic.comic_pages.each do |page|
      page.decrement!(:page) if page.page > params[:page].to_i
    end
    redirect_to comic_path(@comic, anchor: "page-#{[params[:page].to_i, @comic.comic_pages.map(&:page).max].min}")
  end

  private

    def check_user
      @comic = current_user.comics.find_by(id: params[:id])
      @comic = current_user.scanlations.find(params[:id]) unless @comic
      redirect_to Comic.find(params[:id]) unless @comic
    end

    def check_pages
      redirect_to @comic unless @comic.comic_pages.count > 1
    end
end
