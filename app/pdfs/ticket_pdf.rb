require 'open-uri'
require 'mini_magick'

class TicketPdf < Prawn::Document
  def initialize(ticket, base_url)
    super()
    @ticket = ticket
    @base_url = base_url
    header
    text_content
    qr_code
  end

  def header
    text "Match Ticket", size: 30, style: :bold
    move_down 20
  end

  def text_content
    # Define positions for logos and text
    home_team_x = 20
    away_team_x = 270

    bounding_box([0, cursor], width: bounds.width) do
      # Add home team logo and name
      if @ticket.match.home_team.logo.attached?
        io = @ticket.match.home_team.logo.download
        file = Tempfile.new(["home_logo", ".png"], binmode: true)
        file.write(io)
        file.rewind
        image file.path, at: [home_team_x, cursor], width: 50 # Adjust as needed
        file.close
        file.unlink
      end

      # Adjust position for text box to be aligned with the logo
      draw_text "#{@ticket.match.home_team.name}", size: 20, at: [home_team_x + 60, cursor - 20] # Adjust position to raise name

      # Add away team logo and name
      if @ticket.match.away_team.logo.attached?
        io = @ticket.match.away_team.logo.download
        file = Tempfile.new(["away_logo", ".png"], binmode: true)
        file.write(io)
        file.rewind
        image file.path, at: [away_team_x, cursor], width: 50 # Adjust as needed
        file.close
        file.unlink
      end

      # Adjust position for text box to be aligned with the logo
      draw_text "#{@ticket.match.away_team.name}", size: 20, at: [away_team_x + 60, cursor - 20] # Adjust position to raise name

      move_down 60 # Create space below the match details for the rest of the content
    end

    move_down 40

    # Additional details below the match details
    text "Date: #{@ticket.match.date}", size: 20
    text "City: #{@ticket.match.home_team.city}", size: 20
    text "Address: #{@ticket.match.home_team.address}", size: 20
    text "Attendee: #{@ticket.user.email}", size: 20
  end

  def qr_code
    move_down 20
    text "Scan the QR code to view match details", size: 15
    qr = RQRCode::QRCode.new("#{@base_url}/matches/#{@ticket.match.id}")
    print_qr_code(qr)
  end

  def print_qr_code(qr)
    require 'rqrcode'
    png = qr.as_png(size: 200)
    image StringIO.new(png.to_s), at: [50, cursor - 50], width: 150
  end
end
