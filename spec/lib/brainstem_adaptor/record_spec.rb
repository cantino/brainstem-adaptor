require 'spec_helper'

describe BrainstemAdaptor::Record do
  let(:response_data) do
    {
      'count' => 0,
      'results' => [],
      'users' => {
        '12' => { 'name' => 'Petr', 'friend_ids' => ['13'], 'enemy_id' => nil },
        '13' => { 'name' => 'Pelat', 'friend_ids' => [], 'enemy_id' => '12' },
      }
    }
  end

  let(:specification) do
    {
      'users' => {
        'fields' => {
          'name' => {}
        },
        'associations' => {
          'friends' => {
            'foreign_key' => 'friend_ids',
            'collection' => 'users'
          },
          'enemy' => {
            'foreign_key' => 'enemy_id',
            'collection' => 'users'
          }
        }
      }
    }
  end

  let(:response) do
    BrainstemAdaptor::Response.new(response_data, specification)
  end

  subject { described_class.new('users', '12', response) }

  its(:id) { should == '12' }
  its(:collection_name) { should == 'users' }
  its(:response) { should == response }
  its(:associations_specification) { should == specification['users']['associations'] }

  context 'invalid response' do
    context 'collection is not described in specification' do
      let(:specification) { {} }

      specify do
        expect { subject }.to raise_error BrainstemAdaptor::InvalidResponseError, /association/
      end
    end

    context 'collection is not included in response' do
      let(:response_data) { {'count' => 0, 'results' => []} }

      specify do
        expect { subject }.to raise_error BrainstemAdaptor::InvalidResponseError, /collection/
      end
    end

    context 'record is not listed in collection' do
      let(:response_data) { {'count' => 0, 'results' => [], 'users' => {} } }

      specify do
        expect { subject }.to raise_error BrainstemAdaptor::InvalidResponseError, /record/
      end
    end
  end

  describe '#[]' do
    specify do
      expect(subject['name']).to eq('Petr')
    end

    specify do
      expect(subject['friends']).to eq([{'name' => 'Pelat', 'friend_ids' => [], 'enemy_id' => '12'}])
    end

    specify do
      expect(subject['enemy']).to be_nil
    end

    context 'inverse' do
      subject { described_class.new('users', '13', response) }

      specify do
        expect(subject['name']).to eq('Pelat')
      end

      specify do
        expect(subject['friends']).to be_a Enumerable
      end

      specify do
        expect(subject['friends'].any?).to eq(false)
      end

      specify do
        expect(subject['enemy']).to be_a BrainstemAdaptor::Record
      end

      specify do
        expect(subject['enemy']).to eq({'name' => 'Petr', 'friend_ids' => ['13'], 'enemy_id' => nil})
      end
    end
  end

  describe '#has_association?' do
    specify do
      expect(subject.has_association?('friends')).to eq(true)
    end

    specify do
      expect(subject.has_association?('something invalid')).to eq(false)
    end
  end

  describe '#association_by_name' do
    context 'association exists' do
      specify do
        expect(subject.association_by_name('friends')).to be_a BrainstemAdaptor::Association
      end
    end

    context 'association does not exist' do
      specify do
        expect(subject.association_by_name('something wrong')).to be_nil
      end
    end
  end

  context 'no specification set' do
    specify do
      expect { described_class.new('test', 1)['any key'] }.not_to raise_error
    end
  end
end
