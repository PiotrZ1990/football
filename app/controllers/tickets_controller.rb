class TicketsController < ApplicationController
  before_action :authenticate_user!

  def create
    match = Match.find(params[:match_id])
    ticket = match.tickets.build(user: current_user)

    if ticket.save
      redirect_to match_path(match), notice: 'Ticket purchased successfully.'
    else
      redirect_to match_path(match), alert: 'Unable to purchase ticket.'
    end
  end

  def show
    ticket = Ticket.find(params[:id])
    respond_to do |format|
      format.pdf do
        pdf = TicketPdf.new(ticket, request.base_url)
        send_data pdf.render, filename: "ticket_#{ticket.id}.pdf",
                              type: 'application/pdf',
                              disposition: 'inline'
      end
    end
  end
end
