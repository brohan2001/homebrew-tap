class Fileshift < Formula
  desc "Menu bar utility that keeps your newest download on the clean filename"
  homepage "https://github.com/brohan2001/FileShift"
  url "https://github.com/brohan2001/FileShift/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "2fbccdc4d75e4fe2b2260633475d230302a2a8114749a35bcb8a925f59df3683"
  license "MIT"
  head "https://github.com/brohan2001/FileShift.git", branch: "main"

  depends_on macos: :sonoma

  def install
    system "swift", "build", "--disable-sandbox", "-c", "release",
           "--product", "FileShift"
    system "swift", "build", "--disable-sandbox", "-c", "release",
           "--product", "fileshift-cli"
    bin_dir = Pathname(".build/release")

    app = prefix/"FileShift.app"
    (app/"Contents/MacOS").install bin_dir/"FileShift"
    (app/"Contents").install "Resources/Info.plist"
    system "codesign", "--force", "--sign", "-",
           "--identifier", "io.github.brohan2001.FileShift", app
    bin.install bin_dir/"fileshift-cli"
  end

  service do
    run [opt_prefix/"FileShift.app/Contents/MacOS/FileShift"]
    keep_alive successful_exit: false
    process_type :interactive
    error_log_path var/"log/fileshift.log"
  end

  def caveats
    <<~EOS
      Start FileShift now and at every login:
        brew services start fileshift

      On first launch macOS asks whether FileShift may access your Downloads
      folder: click Allow. Activity log: ~/Library/Logs/FileShift/fileshift.log
    EOS
  end

  test do
    output = shell_output("#{bin}/fileshift-cli parse 'my.project.final(2).pdf'")
    assert_match 'clean="my.project.final.pdf"', output

    dir = testpath/"dl"
    dir.mkpath
    (dir/"report.pdf").write "old"
    (dir/"report(1).pdf").write "new"
    system bin/"fileshift-cli", "shift", dir, "report(1).pdf", "--journal", testpath/"journal"
    assert_equal "new", (dir/"report.pdf").read
    assert_equal "old", (dir/"report(1).pdf").read
  end
end
