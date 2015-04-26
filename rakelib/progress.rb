#
# Global progress indicator.
#
class Progress

  #
  # Actual count of compiled files.
  #
  @@actual = 0

  #
  # The count of files to update.
  #
  # Get all the output tasks from the main task prerequisites, and only
  # keep needed ones to get the final count.
  #
  def self.count
    @@cached_count ||= Rake::Task[SUPPORT].prerequisites
      .flat_map { |p| Rake::Task[p].prerequisites.drop 1 }
      .map { |p| Rake::Task[p] }
      .find_all(&:needed?)
      .count
  end

  #
  # Increment the compiled files count.
  #
  def self.inc
    @@actual += 1
  end

  def self.inc_s
    self.inc
    self.to_s
  end

  #
  # Text progress.
  #
  def self.to_s
    "(#{@@actual}/#{self.count})"
  end
end
