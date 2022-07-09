require 'rails_helper'

# Тест на шаблон users/show.html.erb

RSpec.describe 'users/show', type: :view do
  before(:each) do
    user = FactoryBot.build_stubbed(:user, name: 'Вадик', balance: 5000)
    assign(:user, user)
    assign(:games, [ FactoryBot.create(:game_with_questions, user: user) ])

  end

  # Проверяем, что шаблон выводит имена игроков
  it 'renders player names' do
    render
    expect(rendered).to match 'Вадик'
  end

  it 'renders player names in right order' do
    render
    expect(rendered).to match /Дата.*Вопрос.*Выигрыш.*Подсказки/m
  end

  it 'render partial _game' do
    stub_template 'users/_game.html.erb' => "<%= @user.name %><br/>Count of game = <%= @games.count %>"
    render
    expect(rendered).to match 'Вадик'
    expect(rendered).to match 'Count of game = 1'
  end
end
