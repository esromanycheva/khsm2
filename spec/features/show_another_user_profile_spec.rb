require 'rails_helper'

RSpec.feature 'Show another user profile', type: :feature do
  let(:user) { create :user }
  let(:another_user) { create :user }

  let(:game) { create(:game_with_questions, user: another_user, current_level: 5) }

  before do
    game.send(:finish_game!, 1000, false)
    login_as user
  end

  scenario 'successfully' do
    visit "/users/#{another_user.id}"

    expect(page).to have_content "#{another_user.name}"
    expect(page).to have_content '1 000 ₽'
    expect(page).to have_no_content 'Сменить имя и пароль'
  end
end
