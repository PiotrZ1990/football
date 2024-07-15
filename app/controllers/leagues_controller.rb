require 'chunky_png'

class LeaguesController < ApplicationController
  before_action :set_league, only: %i[show edit update destroy]

  # GET /leagues
  # GET /leagues.json
  def index
    @leagues = League.all
  end

  # GET /leagues/1
  # GET /leagues/1.json
  def show
    resize_logo if @league.logo.attached?
  end

  # GET /leagues/new
  def new
    @league = League.new
  end

  # GET /leagues/1/edit
  def edit
  end

  # POST /leagues
  # POST /leagues.json
  def create
    @league = League.new(league_params)

    respond_to do |format|
      if @league.save
        format.html { redirect_to league_url(@league), notice: "League was successfully created." }
        format.json { render :show, status: :created, location: @league }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @league.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /leagues/1
  # PATCH/PUT /leagues/1.json
  def update
    respond_to do |format|
      if @league.update(league_params)
        format.html { redirect_to league_url(@league), notice: "League was successfully updated." }
        format.json { render :show, status: :ok, location: @league }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @league.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /leagues/1
  # DELETE /leagues/1.json
  def destroy
    @league.destroy

    respond_to do |format|
      format.html { redirect_to leagues_url, notice: "League was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  def set_league
    @league = League.find(params[:id])
  end

  # Resize league logo using ChunkyPNG
  def resize_logo
    if @league.logo.attached?
      logo_path = ActiveStorage::Blob.service.path_for(@league.logo.key)

      # Load image using ChunkyPNG
      png = ChunkyPNG::Image.from_file(logo_path)

      # Resize image to fit within 200x200 pixels
      png_resized = png.resize(200, 200)

      # Create a temporary PNG file
      temp_png = Tempfile.new(['resized_logo', '.png'])
      temp_png.binmode

      # Save resized image to temporary file
      png_resized.save(temp_png.path)

      # Attach the resized image as @resized_logo
      @resized_logo_path = temp_png.path

      # Cleanup temporary file after rendering the view
      temp_png.close
      at_exit { temp_png.unlink }
    end
  end

  # Only allow a list of trusted parameters through.
  def league_params
    params.require(:league).permit(:name, :country, :logo)
  end
end
