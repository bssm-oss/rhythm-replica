cask "rhythm-replica" do
  version "0.1.4"
  sha256 "29dc8e88baca73ac096be468f7451e095404a4ecfd1d5c09f9c1f006a5f028e1"

  url "https://github.com/bssm-oss/rhythm-replica/releases/download/v#{version}/RhythmReplica.dmg"
  name "Rhythm Replica"
  desc "Native macOS rhythm game and chart editor"
  homepage "https://github.com/bssm-oss/rhythm-replica"

  app "Rhythm Replica.app"

  postflight do
    system_command "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "#{appdir}/Rhythm Replica.app"]
  end

  zap trash: [
    "~/Library/Application Support/RhythmReplica",
    "~/Library/Caches/com.bssm.rhythmreplica",
    "~/Library/Preferences/com.bssm.rhythmreplica.plist"
  ]
end
