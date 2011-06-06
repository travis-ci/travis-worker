Net::SSH::Shell::Process.class_eval do
  def on_stdout(ch, data)
    # if data.strip =~ /^#{manager.separator} (\d+)$/
    if data.strip =~ /#{manager.separator} (\d+)$/
      before = $`
      output!(before) unless before.empty?
      finished!($1)
    else
      output!(data)
    end
  end
end
