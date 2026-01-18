cask "saneclip" do
  version "1.1"
  sha256 "ffa501c2137b4d68197b8fc7b0c5661c13bb5cd1e9a0de76bad884df26c57d89"

  url "https://github.com/stephanjoseph/SaneClip/releases/download/v#{version}/SaneClip-#{version}.dmg"
  name "SaneClip"
  desc "Beautiful clipboard manager for macOS with Touch ID protection"
  homepage "https://saneclip.com"

  depends_on macos: ">= :sonoma"

  app "SaneClip.app"

  zap trash: [
    "~/Library/Preferences/com.saneclip.app.plist",
    "~/Library/Application Support/SaneClip",
  ]
end
