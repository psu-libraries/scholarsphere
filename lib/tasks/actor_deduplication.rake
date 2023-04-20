desc "Merge duplicate Actor records"
task actor_deduplication: :environment do |_task|
  Actor.where(orcid: nil).each do |actor|
    orcid = OrcidId.new(PsuIdentity::DirectoryService::Client.new.userid(actor.psu_id).orc_id).to_s
    duplicate = Actor.find_by(orcid: orcid)
    if duplicate.present?
      ActiveRecord::Base.transaction do
        duplicate.deposited_works.each { |dw| dw.update depositor_id: actor.id }
        duplicate.proxy_deposited_works.each { |pdw| pdw.update proxy_id: actor.id }
        actor.authorships << duplicate.authorships
        actor.created_work_versions << duplicate.created_work_versions
        actor.created_collections << duplicate.created_collections
        duplicate.deposited_collections.each { |dc| dc.update depositor_id: actor.id }
        actor.save!
        orcid = duplicate.orcid
        duplicate.delete
        # Update ORCiD after deleting duplicate to not raise validation error
        actor.orcid = orcid
        actor.save!
        puts actor.psu_id + ' FIXED'
      end
    end
  rescue PsuIdentity::DirectoryService::NotFound
    puts actor.psu_id + ' NOT FOUND'
  end
end
