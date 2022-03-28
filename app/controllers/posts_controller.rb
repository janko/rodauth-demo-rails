class PostsController < ApplicationController
  before_action :authenticate
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  # GET /posts
  def index
    @posts = current_account.posts.all
  end

  # GET /posts/1
  def show
  end

  # GET /posts/new
  def new
    @post = current_account.posts.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  def create
    @post = current_account.posts.new(post_params)

    if @post.save
      redirect_to @post, notice: 'Post was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /posts/1
  def update
    if @post.update(post_params)
      redirect_to @post, notice: 'Post was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /posts/1
  def destroy
    @post.destroy
    redirect_to posts_url, notice: 'Post was successfully destroyed.', status: 303
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = current_account.posts.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def post_params
      params.require(:post).permit(:title, :body)
    end
end
