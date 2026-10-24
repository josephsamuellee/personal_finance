class ExpenseImportDraft
  def self.write(token, payload)
    FileUtils.mkdir_p(directory)
    File.write(directory.join("#{token}.json"), JSON.generate(payload))
  end

  def self.read(token)
    return if token.blank?

    path = directory.join("#{token}.json")
    return unless path.exist?

    JSON.parse(File.read(path))
  end

  def self.delete(token)
    return if token.blank?

    FileUtils.rm_f(directory.join("#{token}.json"))
  end

  def self.directory
    Rails.root.join("tmp/imports")
  end
end
