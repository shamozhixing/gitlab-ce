require 'rails_helper'

describe UserAbilities do
  context 'anonymous' do
    it 'returns the correct abilities' do
      expect(described_class.abilities(nil, double)).to eq %i(read_user)
    end

    context 'with restricted public level' do
      it 'returns the correct abilities' do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::PUBLIC])

        expect(described_class.abilities(nil, double)).to be_nil
      end
    end
  end

  context 'authenticated' do
    it 'returns the correct abilities' do
      user = double

      expect(described_class.abilities(user, double)).to eq %i(read_user)
    end
  end
end
