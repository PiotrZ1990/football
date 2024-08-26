class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # niezalogowany użytkownik

    if user.admin?
      can :manage, :all # Admin ma pełne uprawnienia
    else
      can :read, :all # Wszyscy użytkownicy mogą czytać
      can :create, Ticket if user.persisted? # Zalogowani użytkownicy mogą kupować bilety
      can :download, Ticket, user_id: user.id # Tylko właściciel biletu może go pobrać
    end
  end
end
