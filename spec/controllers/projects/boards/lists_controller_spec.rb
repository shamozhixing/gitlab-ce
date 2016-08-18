require 'spec_helper'

describe Projects::Boards::ListsController do
  let(:project) { create(:project_with_board) }
  let(:board)   { project.board }
  let(:user)    { create(:user) }
  let(:guest)   { create(:user) }

  before do
    project.team << [user, :master]
    project.team << [guest, :guest]
  end

  describe 'GET index' do
    it 'returns a successful 200 response' do
      read_board_list user: user

      expect(response).to have_http_status(200)
      expect(response.content_type).to eq 'application/json'
    end

    it 'returns a list of board lists' do
      board = project.create_board
      create(:backlog_list, board: board)
      create(:list, board: board)
      create(:done_list, board: board)

      read_board_list user: user

      parsed_response = JSON.parse(response.body)

      expect(response).to match_response_schema('lists')
      expect(parsed_response.length).to eq 3
    end

    context 'with unauthorized user' do
      before do
        allow(Ability.abilities).to receive(:allowed?).with(user, :read_project, project).and_return(true)
        allow(Ability.abilities).to receive(:allowed?).with(user, :read_list, project).and_return(false)
      end

      it 'returns a successful 403 response' do
        read_board_list user: user

        expect(response).to have_http_status(403)
      end
    end

    def read_board_list(user:)
      sign_in(user)

      get :index, namespace_id: project.namespace.to_param,
                  project_id: project.to_param,
                  format: :json
    end
  end

  describe 'POST create' do
    let(:label) { create(:label, project: project, name: 'Development') }

    context 'with valid params' do
      it 'returns a successful 200 response' do
        create_board_list user: user, label_id: label.id

        expect(response).to have_http_status(200)
      end

      it 'returns the created list' do
        create_board_list user: user, label_id: label.id

        expect(response).to match_response_schema('list')
      end
    end

    context 'with invalid params' do
      it 'returns an error' do
        create_board_list user: user, label_id: nil

        parsed_response = JSON.parse(response.body)

        expect(parsed_response['label']).to contain_exactly "can't be blank"
        expect(response).to have_http_status(422)
      end
    end

    context 'with unauthorized user' do
      let(:label) { create(:label, project: project, name: 'Development') }

      it 'returns a successful 403 response' do
        create_board_list user: guest, label_id: label.id

        expect(response).to have_http_status(403)
      end
    end

    def create_board_list(user:, label_id:)
      sign_in(user)

      post :create, namespace_id: project.namespace.to_param,
                    project_id: project.to_param,
                    list: { label_id: label_id },
                    format: :json
    end
  end

  describe 'PATCH update' do
    let!(:planning)    { create(:list, board: board, position: 0) }
    let!(:development) { create(:list, board: board, position: 1) }

    context 'with valid position' do
      it 'returns a successful 200 response' do
        move user: user, list: planning, position: 1

        expect(response).to have_http_status(200)
      end

      it 'moves the list to the desired position' do
        move user: user, list: planning, position: 1

        expect(planning.reload.position).to eq 1
      end
    end

    context 'with invalid position' do
      it 'returns a unprocessable entity 422 response' do
        move user: user, list: planning, position: 6

        expect(response).to have_http_status(422)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        move user: user, list: 999, position: 1

        expect(response).to have_http_status(404)
      end
    end

    context 'with unauthorized user' do
      it 'returns a successful 403 response' do
        move user: guest, list: planning, position: 6

        expect(response).to have_http_status(403)
      end
    end

    def move(user:, list:, position:)
      sign_in(user)

      patch :update, namespace_id: project.namespace.to_param,
                     project_id: project.to_param,
                     id: list.to_param,
                     list: { position: position },
                     format: :json
    end
  end

  describe 'DELETE destroy' do
    let!(:planning) { create(:list, board: board, position: 0) }

    context 'with valid list id' do
      it 'returns a successful 200 response' do
        remove_board_list user: user, list: planning

        expect(response).to have_http_status(200)
      end

      it 'removes list from board' do
        expect { remove_board_list user: user, list: planning }.to change(board.lists, :size).by(-1)
      end
    end

    context 'with invalid list id' do
      it 'returns a not found 404 response' do
        remove_board_list user: user, list: 999

        expect(response).to have_http_status(404)
      end
    end

    context 'with unauthorized user' do
      it 'returns a successful 403 response' do
        remove_board_list user: guest, list: planning

        expect(response).to have_http_status(403)
      end
    end

    def remove_board_list(user:, list:)
      sign_in(user)

      delete :destroy, namespace_id: project.namespace.to_param,
                       project_id: project.to_param,
                       id: list.to_param,
                       format: :json
    end
  end

  describe 'POST generate' do
    context 'when board lists is empty' do
      it 'returns a successful 200 response' do
        generate_default_board_lists user: user

        expect(response).to have_http_status(200)
      end

      it 'returns the defaults lists' do
        generate_default_board_lists user: user

        expect(response).to match_response_schema('lists')
      end
    end

    context 'when board lists is not empty' do
      it 'returns a unprocessable entity 422 response' do
        create(:list, board: board)

        generate_default_board_lists user: user

        expect(response).to have_http_status(422)
      end
    end

    context 'with unauthorized user' do
      it 'returns a successful 403 response' do
        generate_default_board_lists user: guest

        expect(response).to have_http_status(403)
      end
    end

    def generate_default_board_lists(user:)
      sign_in(user)

      post :generate, namespace_id: project.namespace.to_param,
                      project_id: project.to_param,
                      format: :json
    end
  end
end
