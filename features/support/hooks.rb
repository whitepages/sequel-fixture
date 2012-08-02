After do
  Fast.dir.remove! :test
  @DB.tables do |table|
    @DB.drop_table table
  end
end
