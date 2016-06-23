require 'spec_helper'

describe API::Members, api: true  do
  include ApiHelpers

  let(:master) { create(:user) }
  let(:developer) { create(:user) }
  let(:access_requester) { create(:user) }
  let(:stranger) { create(:user) }

  let(:project) do
    project = create(:project, :public, creator_id: master.id, namespace: master.namespace)
    project.team << [developer, :developer]
    project.team << [master, :master]
    project.request_access(access_requester)
    project
  end

  let!(:group) do
    group = create(:group, :public)
    group.add_developer(developer)
    group.add_owner(master)
    group.request_access(access_requester)
    group
  end

  shared_examples 'GET /:sources/:id/members' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get api("/#{source_type.pluralize}/#{source.id}/members", stranger) }
      end

      context 'when authenticated as a non-member' do
        %i[access_requester stranger].each do |type|
          context "as a #{type}" do
            it 'returns 200' do
              user = public_send(type)
              get api("/#{source_type.pluralize}/#{source.id}/members", user)

              expect(response).to have_http_status(200)
              expect(json_response.size).to eq(2)
            end
          end
        end
      end

      it 'finds members with query string' do
        get api("/#{source_type.pluralize}/#{source.id}/members", developer), query: master.username

        expect(response).to have_http_status(200)
        expect(json_response.count).to eq(1)
        expect(json_response.first['username']).to eq(master.username)
      end
    end
  end

  shared_examples 'GET /:sources/:id/members/:user_id' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", stranger) }
      end

      context 'when authenticated as a non-member' do
        %i[access_requester stranger].each do |type|
          context "as a #{type}" do
            it 'returns 200' do
              user = public_send(type)
              get api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", user)

              expect(response).to have_http_status(200)
              # User attributes
              expect(json_response['id']).to eq(developer.id)
              expect(json_response['name']).to eq(developer.name)
              expect(json_response['username']).to eq(developer.username)
              expect(json_response['state']).to eq(developer.state)
              expect(json_response['avatar_url']).to eq(developer.avatar_url)
              expect(json_response['web_url']).to eq(Gitlab::Routing.url_helpers.user_url(developer))

              # Member attributes
              expect(json_response['access_level']).to eq(Member::DEVELOPER)
            end
          end
        end
      end
    end
  end

  shared_examples 'POST /:sources/:id/members' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { post api("/#{source_type.pluralize}/#{source.id}/members", stranger) }
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              post api("/#{source_type.pluralize}/#{source.id}/members", user)

              expect(response).to have_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a master/owner' do
        context 'and new member is already a requester' do
          it 'transforms the requester into a proper member' do
            expect do
              post api("/#{source_type.pluralize}/#{source.id}/members", master),
                   user_id: access_requester.id, access_level: Member::MASTER

              expect(response).to have_http_status(201)
            end.to change { source.members.count }.by(1)
            expect(source.requesters.count).to eq(0)
            expect(json_response['id']).to eq(access_requester.id)
            expect(json_response['access_level']).to eq(Member::MASTER)
          end
        end

        it 'creates a new member' do
          expect do
            post api("/#{source_type.pluralize}/#{source.id}/members", master),
                 user_id: stranger.id, access_level: Member::DEVELOPER

            expect(response).to have_http_status(201)
          end.to change { source.members.count }.by(1)
          expect(json_response['id']).to eq(stranger.id)
          expect(json_response['access_level']).to eq(Member::DEVELOPER)
        end
      end

      it "returns #{source_type == 'project' ? 201 : 409} if member already exists" do
        post api("/#{source_type.pluralize}/#{source.id}/members", master),
             user_id: master.id, access_level: Member::MASTER

        expect(response).to have_http_status(409)
      end

      it 'returns 400 when user_id is not given' do
        post api("/#{source_type.pluralize}/#{source.id}/members", master),
             access_level: Member::MASTER

        expect(response).to have_http_status(400)
      end

      it 'returns 400 when access_level is not given' do
        post api("/#{source_type.pluralize}/#{source.id}/members", master),
             user_id: stranger.id

        expect(response).to have_http_status(400)
      end

      it 'returns 400 when access_level is not valid' do
        post api("/#{source_type.pluralize}/#{source.id}/members", master),
             user_id: stranger.id, access_level: 1234

        expect(response).to have_http_status(400)
      end
    end
  end

  shared_examples 'PUT /:sources/:id/members/:user_id' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { put api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", stranger) }
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger developer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              put api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", user)

              expect(response).to have_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a master/owner' do
        it 'updates the member' do
          put api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", master),
              access_level: Member::MASTER

          expect(response).to have_http_status(200)
          expect(json_response['id']).to eq(developer.id)
          expect(json_response['access_level']).to eq(Member::MASTER)
        end
      end

      it 'returns 409 if member does not exist' do
        put api("/#{source_type.pluralize}/#{source.id}/members/123", master),
            access_level: Member::MASTER

        expect(response).to have_http_status(404)
      end

      it 'returns 400 when access_level is not given' do
        put api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", master)

        expect(response).to have_http_status(400)
      end

      it 'returns 400 when access level is not valid' do
        put api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", master),
            access_level: 1234

        expect(response).to have_http_status(400)
      end
    end
  end

  shared_examples 'DELETE /:sources/:id/members/:user_id' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { delete api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", stranger) }
      end

      context 'when authenticated as a non-member or member with insufficient rights' do
        %i[access_requester stranger].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              delete api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", user)

              expect(response).to have_http_status(403)
            end
          end
        end
      end

      context 'when authenticated as a member and deleting themself' do
        it 'deletes the member' do
          expect do
            delete api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", developer)

            expect(response).to have_http_status(204)
          end.to change { source.members.count }.by(-1)
        end
      end

      context 'when authenticated as a master/owner' do
        context 'and member is a requester' do
          it 'returns 404' do
            expect do
              delete api("/#{source_type.pluralize}/#{source.id}/members/#{access_requester.id}", master)

              expect(response).to have_http_status(404)
            end.not_to change { source.requesters.count }
          end
        end

        it 'deletes the member' do
          expect do
            delete api("/#{source_type.pluralize}/#{source.id}/members/#{developer.id}", master)

            expect(response).to have_http_status(204)
          end.to change { source.members.count }.by(-1)
        end
      end

      it 'returns 409 if member does not exist' do
        delete api("/#{source_type.pluralize}/#{source.id}/members/123", master)

        expect(response).to have_http_status(404)
      end
    end
  end

  it_behaves_like 'GET /:sources/:id/members', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'GET /:sources/:id/members', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'GET /:sources/:id/members/:user_id', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'GET /:sources/:id/members/:user_id', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'POST /:sources/:id/members', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'POST /:sources/:id/members', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'PUT /:sources/:id/members/:user_id', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'PUT /:sources/:id/members/:user_id', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'DELETE /:sources/:id/members/:user_id', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'DELETE /:sources/:id/members/:user_id', 'group' do
    let(:source) { group }
  end
end
