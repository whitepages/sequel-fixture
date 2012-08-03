After do
  Fast.dir.remove! :test, :fixtures
  @DB.tables do |table|
    @DB.drop_table table
  end
end
