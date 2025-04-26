# frozen_string_literal: true

# spec/user_spec.rb
require 'spec_helper' # RSpecの共通設定

RSpec.describe User do
  let(:user) { User.new('Taro', 'Yamada') }

  describe 'derived attribute full_name' do
    it 'returns correct initial full name' do
      expect(user.full_name).to eq('Taro Yamada')
    end

    it 'updates when first_name changes' do
      user.first_name = 'Jiro'
      expect(user.full_name).to eq('Jiro Yamada')
    end

    it 'updates when last_name changes' do
      user.last_name = 'Suzuki'
      expect(user.full_name).to eq('Taro Suzuki')
    end

    it 'does not store full_name as instance variable' do
      expect(user.instance_variables).not_to include(:@full_name)
    end
  end
end
