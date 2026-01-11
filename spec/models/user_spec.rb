# frozen_string_literal: true

require 'spec_helper'

RSpec.describe User, type: :model do
  before do
    create(:blog)
  end

  describe 'validations' do
    it 'validates presence of login' do
      user = build(:user, login: nil)
      expect(user).not_to be_valid
      expect(user.errors[:login]).to include("can't be blank")
    end

    it 'validates presence of email' do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'validates uniqueness of login' do
      create(:user, login: 'testuser')
      user2 = build(:user, login: 'testuser')
      expect(user2).not_to be_valid
      expect(user2.errors[:login]).to include('has already been taken')
    end

    it 'validates uniqueness of email' do
      create(:user, email: 'test@example.com')
      user2 = build(:user, email: 'test@example.com')
      expect(user2).not_to be_valid
      expect(user2.errors[:email]).to include('has already been taken')
    end

    it 'validates password length between 5 and 40' do
      user = build(:user, password: 'abc')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too short (minimum is 5 characters)')
    end

    it 'validates login length between 3 and 40' do
      user = build(:user, login: 'ab')
      expect(user).not_to be_valid
      expect(user.errors[:login]).to include('is too short (minimum is 3 characters)')
    end
  end

  describe 'associations' do
    it 'belongs to profile' do
      profile = create(:profile_admin)
      user = create(:user, profile: profile)
      expect(user.profile).to eq(profile)
    end

    it 'has many articles' do
      user = create(:user)
      article = create(:article, user: user)
      expect(user.articles).to include(article)
    end
  end

  describe '.authenticate' do
    it 'returns user with correct credentials' do
      user = create(:user, login: 'testuser', password: 'secret123')
      authenticated = User.authenticate('testuser', 'secret123')
      expect(authenticated).to eq(user)
    end

    it 'returns nil with incorrect password' do
      create(:user, login: 'testuser', password: 'secret123')
      expect(User.authenticate('testuser', 'wrongpass')).to be_nil
    end

    it 'returns nil with non-existent user' do
      expect(User.authenticate('nonexistent', 'password')).to be_nil
    end

    it 'returns nil for inactive user' do
      user = create(:user, login: 'testuser', password: 'secret123')
      user.update_column(:state, 'inactive')
      expect(User.authenticate('testuser', 'secret123')).to be_nil
    end
  end

  describe '.authenticate?' do
    it 'returns true for valid credentials' do
      create(:user, login: 'testuser', password: 'secret123')
      expect(User.authenticate?('testuser', 'secret123')).to be true
    end

    it 'returns false for invalid credentials' do
      create(:user, login: 'testuser', password: 'secret123')
      expect(User.authenticate?('testuser', 'wrongpass')).to be false
    end
  end

  describe '.find_by_permalink' do
    it 'finds user by login' do
      user = create(:user, login: 'testuser')
      expect(User.find_by_permalink('testuser')).to eq(user)
    end

    it 'raises RecordNotFound for non-existent user' do
      expect { User.find_by_permalink('nonexistent') }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#admin?' do
    it 'returns true for admin profile' do
      profile = create(:profile_admin)
      user = create(:user, profile: profile)
      expect(user.admin?).to be true
    end

    it 'returns false for non-admin profile' do
      profile = create(:profile_contributor)
      user = create(:user, profile: profile)
      expect(user.admin?).to be false
    end
  end

  describe '#name' do
    it 'returns name if set' do
      user = create(:user, name: 'John Doe')
      expect(user.name).to eq('John Doe')
    end

    it 'returns firstname lastname if name is blank' do
      user = create(:user, name: '')
      user.firstname = 'John'
      user.lastname = 'Doe'
      expect(user.name).to eq('John Doe')
    end

    it 'returns login if name and firstname/lastname are blank' do
      user = create(:user, name: '', login: 'johnd')
      user.firstname = ''
      user.lastname = ''
      expect(user.name).to eq('johnd')
    end
  end

  describe '#display_name' do
    it 'returns name' do
      user = create(:user, name: 'John Doe')
      expect(user.display_name).to eq('John Doe')
    end
  end

  describe '#permalink' do
    it 'returns login' do
      user = create(:user, login: 'johnd')
      expect(user.permalink).to eq('johnd')
    end
  end

  describe '#to_param' do
    it 'returns permalink' do
      user = create(:user, login: 'johnd')
      expect(user.to_param).to eq('johnd')
    end
  end

  describe '#article_counter' do
    it 'returns count of user articles' do
      user = create(:user)
      create(:article, user: user)
      create(:article, user: user)
      expect(user.article_counter).to eq(2)
    end
  end

  describe '#simple_editor?' do
    it 'returns true when editor is simple' do
      user = create(:user)
      user.editor = 'simple'
      expect(user.simple_editor?).to be true
    end

    it 'returns false when editor is visual' do
      user = create(:user)
      user.editor = 'visual'
      expect(user.simple_editor?).to be false
    end
  end

  describe '#remember_me' do
    it 'sets remember token for 2 weeks' do
      user = create(:user)
      user.remember_me
      expect(user.remember_token).to be_present
      expect(user.remember_token_expires_at).to be > 13.days.from_now
    end
  end

  describe '#forget_me' do
    it 'clears remember token' do
      user = create(:user)
      user.remember_me
      user.forget_me
      expect(user.remember_token).to be_nil
      expect(user.remember_token_expires_at).to be_nil
    end
  end

  describe '#project_modules' do
    it 'returns profile project_modules' do
      profile = create(:profile_admin)
      user = create(:user, profile: profile)
      expect(user.project_modules).to eq(profile.project_modules)
    end

    it 'returns empty array when no profile' do
      user = build(:user, profile: nil)
      user.save(validate: false)
      expect(user.project_modules).to eq([])
    end
  end

  describe '#update_connection_time' do
    it 'updates last_connection' do
      user = create(:user)
      old_time = 1.day.ago
      user.update_column(:last_connection, old_time)
      user.update_connection_time
      expect(user.last_connection).to be > old_time
    end
  end

  describe 'password encryption' do
    it 'encrypts password on create' do
      user = create(:user, password: 'secret123')
      expect(user.password).not_to eq('secret123')
    end

    it 'encrypts password on update when changed' do
      user = create(:user, password: 'secret123')
      old_password = user.password
      user.password = 'newpassword'
      user.save
      expect(user.password).not_to eq(old_password)
    end
  end

  describe 'default profile assignment' do
    it 'assigns admin profile to first user' do
      User.delete_all
      Profile.delete_all
      create(:profile_admin, label: 'admin')
      user = create(:user, profile: nil)
      expect(user.profile.label).to eq('admin')
    end

    it 'assigns contributor profile to subsequent users' do
      User.delete_all
      Profile.delete_all
      create(:profile_admin, label: 'admin')
      create(:profile_contributor, label: 'contributor')
      create(:user, profile: nil) # first user gets admin
      user2 = create(:user, profile: nil)
      expect(user2.profile.label).to eq('contributor')
    end
  end

  describe '#permalink_url' do
    it 'returns author URL' do
      user = create(:user, login: 'testuser')
      url = user.permalink_url
      expect(url).to include('author')
      expect(url).to include('testuser')
    end
  end
end
