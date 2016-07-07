require 'spec_helper'

describe Ability, lib: true do
  describe '#allowed' do
    # TODO (rspeicher): This is temporary
    context 'old and busted' do
      context 'with nil user' do
        it 'returns a default set of abilities' do
          expect(described_class).to receive(:anonymous_abilities).and_call_original

          expect(described_class.allowed(nil, double)).not_to be_nil
        end
      end

      context 'with non-User object' do
        it 'returns an empty set of abilities' do
          user = double

          expect(described_class.allowed(user, double)).to eq []
        end
      end

      context 'with blocked user' do
        it 'returns an empty set of abilities' do
          user = build_stubbed(:user)

          expect(user).to receive(:blocked?).and_return(true)

          expect(described_class.allowed(user, double)).to eq []
        end
      end
    end

    # TODO (rspeicher): This is temporary
    context 'new hotness' do
      it "delegates to a subject's Abilities class" do
        user = build_stubbed(:user)
        project = build_stubbed(:project)

        expect(ProjectAbilities).to receive(:abilities).with(user, project)

        described_class.allowed(user, project)
      end
    end
  end

  describe '.users_that_can_read_project' do
    context 'using a public project' do
      it 'returns all the users' do
        project = create(:project, :public)
        user = build(:user)

        expect(described_class.users_that_can_read_project([user], project)).
          to eq([user])
      end
    end

    context 'using an internal project' do
      let(:project) { create(:project, :internal) }

      it 'returns users that are administrators' do
        user = build(:user, admin: true)

        expect(described_class.users_that_can_read_project([user], project)).
          to eq([user])
      end

      it 'returns internal users while skipping external users' do
        user1 = build(:user)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns external users if they are the project owner' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project).to receive(:owner).twice.and_return(user1)

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns external users if they are project members' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project.team).to receive(:members).twice.and_return([user1])

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns an empty Array if all users are external users without access' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([])
      end
    end

    context 'using a private project' do
      let(:project) { create(:project, :private) }

      it 'returns users that are administrators' do
        user = build(:user, admin: true)

        expect(described_class.users_that_can_read_project([user], project)).
          to eq([user])
      end

      it 'returns external users if they are the project owner' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project).to receive(:owner).twice.and_return(user1)

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns external users if they are project members' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(project.team).to receive(:members).twice.and_return([user1])

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([user1])
      end

      it 'returns an empty Array if all users are internal users without access' do
        user1 = build(:user)
        user2 = build(:user)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([])
      end

      it 'returns an empty Array if all users are external users without access' do
        user1 = build(:user, external: true)
        user2 = build(:user, external: true)
        users = [user1, user2]

        expect(described_class.users_that_can_read_project(users, project)).
          to eq([])
      end
    end
  end
end
