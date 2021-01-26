# frozen_string_literal: true

class AuthorshipDiff
  # @param obj1 [WorkVersion]
  # @param obj2 [WorkVersion]
  def self.call(*args)
    new(*args).diff
  end

  attr_reader :base_version, :comparison_version

  def initialize(*args)
    @base_version = args[0]
    @comparison_version = args[1]
  end

  def diff
    { renamed: renamed, deleted: deleted, added: added }
  end

  # @return [Array<[Authorship, Authorship]>]
  def renamed
    identical_authorship_instance_tokens.map do |instance_token|
      original_creator = base_version_creators.find { |creator| creator.instance_token == instance_token }
      renamed_creator = comparison_version_creators.find { |creator| creator.instance_token == instance_token }
      next if original_creator.alias == renamed_creator.alias

      [original_creator, renamed_creator]
    end.compact
  end

  # @return [Array<Authorship>]
  def deleted
    base_version_creators.reject do |creator|
      identical_authorship_instance_tokens.include?(creator.instance_token)
    end
  end

  # @return [Array<Authorship>]
  def added
    comparison_version_creators.reject do |creator|
      identical_authorship_instance_tokens.include?(creator.instance_token)
    end
  end

  private

    def base_version_creators
      @base_version_creators ||= base_version.creators
    end

    def comparison_version_creators
      @comparison_version_creators ||= comparison_version.creators
    end

    def identical_authorship_instance_tokens
      @identical_authorship_instance_tokens ||= begin
        base = Set.new(base_version_creators.map(&:instance_token))
        comparison = Set.new(comparison_version_creators.map(&:instance_token))

        base.intersection(comparison)
      end
    end
end
