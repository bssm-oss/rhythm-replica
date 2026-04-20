cask "rhythm-replica" do
  version "0.1.3"
  sha256 "10fb70f45faee345a7f54281711006f0a9dfc133f303084a18334db3a8cf113b"

  url "https://github.com/bssm-oss/rhythm-replica/releases/download/v#{version}/RhythmReplica.dmg"
  name "Rhythm Replica"
  desc "Native macOS rhythm game and chart editor"
  homepage "https://github.com/bssm-oss/rhythm-replica"

  app "Rhythm Replica.app"

  zap trash: [
    "~/Library/Application Support/RhythmReplica",
    "~/Library/Caches/com.bssm.rhythmreplica",
    "~/Library/Preferences/com.bssm.rhythmreplica.plist"
  ]
end
