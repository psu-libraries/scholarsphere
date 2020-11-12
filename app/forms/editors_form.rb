# frozen_string_literal: true

class EditorsForm
  include ActiveModel::Model

  attr_reader :work, :user

  def initialize(work:, params:, user:)
    @work = work
    @user = user
    super(params)
  end

  def edit_users
    @edit_users || work.edit_users.map(&:access_id)
  end

  def edit_users=(access_ids)
    @edit_users = access_ids.reject(&:blank?)
  end

  def edit_groups
    @edit_groups || work.edit_groups.map(&:name)
  end

  def edit_groups=(names)
    @edit_groups = names.reject(&:blank?)
  end

  def group_options
    (user.groups - User.default_groups).map(&:name)
  end

  def save
    user_list = build_users
    return false if errors.present?

    work.edit_users = user_list
    work.edit_groups = group_list
    work.save
  end

  private

    def build_users
      edit_users.map do |access_id|
        UserRegistrationService.call(uid: access_id) ||
          errors.add(:edit_users, "#{access_id} does not exist") && access_id
      end
    end

    def group_list
      edit_groups.map do |name|
        Group.find_by(name: name)
      end.compact
    end
end
