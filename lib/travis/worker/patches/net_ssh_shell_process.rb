# can be removed once v0.2.0 is available
# see https://github.com/mitchellh/net-ssh-shell/commit/1ebd62670b77b5834f0c6dd1a4508cb881a3ed64

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
