cask "rhythm-replica" do
  version "0.1.0"
  sha256 "REPLACE_WITH_RELEASE_SHA256"

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
