cask "rhythm-replica" do
  version "0.1.3"
  sha256 "493085428c66afeee0e13547f2095430e0a23a35da99b301feece1a1cc9571ee"

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
