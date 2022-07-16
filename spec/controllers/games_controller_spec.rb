# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами
# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryBot.create(:user) }
  # админ
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  context 'Anon' do
    describe '#show' do
      before do
        get :show, id: game_w_questions.id
      end

      it 'not return http status 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to login user' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'show alert flash' do
        expect(flash[:alert]).to be
      end
    end

    describe '#create' do
      before do
        generate_questions(15)
        post :create
      end

      it 'not assign game' do
        game = assigns(:game)
        expect(game).to be nil
      end

      it 'not return http status 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to login user' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'show alert flash' do
        expect(flash[:alert]).to be
      end
    end

    describe '#answer' do
      before do
        put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
      end

      it 'not assign game' do
        game = assigns(:game)
        expect(game).to be nil
      end

      it 'not return http status 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to login user' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'show alert flash' do
        expect(flash[:alert]).to be
      end
    end

    describe '#help' do
      before do
        put :help, id: game_w_questions.id, help_type: :audience_help
      end

      it 'not assign game' do
        game = assigns(:game)
        expect(game).to be nil
      end

      it 'not return http status 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to login user' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'show alert flash' do
        expect(flash[:alert]).to be
      end
    end

    describe '#take_money' do
      before do
        game_w_questions.update(current_level: 5)
        put :take_money, id: game_w_questions.id
      end

      it 'not assign game' do
        game = assigns(:game)
        expect(game).to be nil
      end

      it 'not return http status 200' do
        expect(response.status).not_to eq(200)
      end

      it 'redirect to login user' do
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'show alert flash' do
        expect(flash[:alert]).to be
      end
    end
  end

  context 'Usual user' do
    before { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

    describe '#create' do
      context 'create first game' do
        before do
          generate_questions(15)
          post :create
        end

        it 'has game' do
          game = assigns(:game)
          expect(game).to be
        end

        it 'game not finished' do
          game = assigns(:game)
          expect(game.finished?).to be false
        end

        it 'has user' do
          game = assigns(:game)
          expect(game.user).to eq(user)
        end

        it 'redirect to created game' do
          game = assigns(:game)
          expect(response).to redirect_to(game_path(game))
        end

        it 'show notice flash' do
          expect(flash[:notice]).to be
        end
      end

      context 'second game' do
        before do
          game_w_questions
          generate_questions(15)
          post :create
        end

        it 'not assign game' do
          game = assigns(:game)
          expect(game).to be nil
        end

        it 'not return http status 200' do
          expect(response.status).not_to eq(200)
        end

        it 'redirect to first game' do
          expect(response).to redirect_to(game_path(game_w_questions))
        end

        it 'show alert flash' do
          expect(flash[:alert]).to be
        end
      end
    end

    describe '#show' do
      context "self game" do
        before do
          get :show, id: game_w_questions.id
        end

        it 'has game' do
          game = assigns(:game)
          expect(game).to be
        end

        it 'game not finished' do
          game = assigns(:game)
          expect(game.finished?).to be false
        end

        it 'has user' do
          game = assigns(:game)
          expect(game.user).to eq(user)
        end

        it 'responce 200' do
          expect(response.status).to eq(200)
        end

        it 'render show' do
          expect(response).to render_template('show')
        end
      end

      context 'alian game' do
        before do
          alien_game = FactoryBot.create(:game_with_questions)
          get :show, id: alien_game.id
        end

        it 'not return http status 200' do
          expect(response.status).not_to eq(200)
        end

        it 'redirect to root' do
          expect(response).to redirect_to(root_path)
        end

        it 'show alert flash' do
          expect(flash[:alert]).to be
        end
      end
    end

    describe "#answer" do
      context 'correct answer' do
        before do
          put :answer, id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key
        end
        it 'game not finished' do
          game = assigns(:game)
          expect(game.finished?).to be false
        end

        it 'has level > 0' do
          game = assigns(:game)
          expect(game.current_level).to be > 0
        end

        it 'redirect to game' do
          game = assigns(:game)
          expect(response).to redirect_to(game_path(game))
        end

        it 'not show any flash' do
          expect(flash.empty?).to be_truthy # удачный ответ не заполняет flash
        end
      end

      context 'incorrect answer' do
        before do
          incorect_answer = (['a', 'b', 'c', 'd'] - [game_w_questions.current_game_question.correct_answer_key]).sample
          put :answer, id: game_w_questions.id, letter: incorect_answer
        end

        it 'game finished' do
          game = assigns(:game)
          expect(game.finished?).to be true
        end

        it 'has level = 0' do
          game = assigns(:game)
          expect(game.current_level).to eq 0
        end

        it 'has balance = 0' do
          user.reload
          expect(user.balance).to eq(0)
        end

        it 'redirect to game' do
          game = assigns(:game)
          expect(response).to redirect_to(user_path(user))
        end

        it 'show alert flash' do
          expect(flash[:alert]).to be
        end
      end
    end

    describe '#help' do
      context 'call audience_help' do
        before do
          put :help, id: game_w_questions.id, help_type: :audience_help
        end

        it 'game not finished' do
          game = assigns(:game)
          expect(game.finished?).to be false
        end

        it 'used audience help' do
          game = assigns(:game)
          expect(game.audience_help_used).to be_truthy
        end

        it 'has a audience_help' do
          game = assigns(:game)
          expect(game.current_game_question.help_hash[:audience_help]).to be
        end

        it 'contain variants in audience_help' do
          game = assigns(:game)
          expect(game.current_game_question.help_hash[:audience_help].keys).to contain_exactly('a', 'b', 'c', 'd')
        end

        it 'redirect to game' do
          game = assigns(:game)
          expect(response).to redirect_to(game_path(game))
        end
      end

      context 'call fifty_fifty' do
        before do
          put :help, id: game_w_questions.id, help_type: :fifty_fifty
        end

        it 'game not finished' do
          game = assigns(:game)
          expect(game.finished?).to be false
        end

        it 'used audience help' do
          game = assigns(:game)
          expect(game.fifty_fifty_used).to be_truthy
        end

        it 'has a audience_help' do
          game = assigns(:game)
          expect(game.current_game_question.help_hash[:fifty_fifty]).to be
        end

        it 'contain variants in audience_help' do
          game = assigns(:game)
          fifty_fifty = game.current_game_question.help_hash[:fifty_fifty]
          expect(fifty_fifty.count).to eq 2
        end

        it 'redirect to game' do
          game = assigns(:game)
          expect(response).to redirect_to(game_path(game))
        end
      end

    end

    describe '#take' do
      before do
        game_w_questions.update(current_level: 5)
        put :take_money, id: game_w_questions.id
      end

      it 'has a level 5' do
        game = assigns(:game)
        expect(game.current_level).to eq 5
      end

      it 'has a prize = 1000' do
        game = assigns(:game)
        expect(game.prize).to eq(1000)
      end

      it 'finished game' do
        game = assigns(:game)
        expect(game.finished?).to eq true
      end
      it 'has a balance = 1000' do
        user.reload
        expect(user.balance).to eq(1000)
      end

      it 'redirect to user' do
        game = assigns(:game)
        expect(response).to redirect_to(user_path(game))
      end

      it 'show warning flash' do
        expect(flash[:warning]).to be
      end
    end
  end
end
