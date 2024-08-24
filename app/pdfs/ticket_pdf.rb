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
    text "Match: #{@ticket.match.home_team.name} vs #{@ticket.match.away_team.name}", size: 20
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
    # Konwertowanie QRCode do obrazu
    png = qr.as_png(size: 200)
    image StringIO.new(png.to_s), at: [50, 450], width: 150
  end
end
