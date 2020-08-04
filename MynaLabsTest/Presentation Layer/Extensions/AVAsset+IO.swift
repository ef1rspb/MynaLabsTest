import AVFoundation

/// Source: https://stackoverflow.com/a/42741683
extension AVAsset {
  // Provide a URL for where you wish to write
  // the audio file if successful
  func writeAudioTrack(to url: URL,
                       success: @escaping () -> (),
                       failure: @escaping (Error) -> ()) {
    do {
      let asset = try audioAsset()
      asset.write(to: url, success: success, failure: failure)
    } catch {
      failure(error)
    }
  }

  private func write(to url: URL,
                     success: @escaping () -> (),
                     failure: @escaping (Error) -> ()) {
    // Create an export session that will output an
    // audio track (M4A file)
    do { // delete old video
      try FileManager.default.removeItem(at: url)
    }
    catch {
      print(error.localizedDescription)
    }

    guard let exportSession = AVAssetExportSession(asset: self,
                                                   presetName: AVAssetExportPresetPassthrough) else {
                                                    // This is just a generic error
                                                    let error = NSError(domain: "domain",
                                                                        code: 0,
                                                                        userInfo: nil)
                                                    failure(error)

                                                    return
    }

    exportSession.outputFileType = .caf
    exportSession.outputURL = url

    exportSession.exportAsynchronously {
      switch exportSession.status {
        case .completed:
          success()
        case .unknown, .waiting, .exporting, .failed, .cancelled:
          let error = NSError(domain: "domain", code: 0, userInfo: nil)
          failure(error)
      }
    }
  }

  private func audioAsset() throws -> AVAsset {
    // Create a new container to hold the audio track
    let composition = AVMutableComposition()
    // Create an array of audio tracks in the given asset
    // Typically, there is only one
    let audioTracks = tracks(withMediaType: .audio)

    // Iterate through the audio tracks while
    // Adding them to a new AVAsset
    for track in audioTracks {
      let compositionTrack = composition.addMutableTrack(withMediaType: .audio,
                                                         preferredTrackID: kCMPersistentTrackID_Invalid)
      do {
        // Add the current audio track at the beginning of
        // the asset for the duration of the source AVAsset
        try compositionTrack?.insertTimeRange(track.timeRange,
                                              of: track,
                                              at: track.timeRange.start)
      } catch {
        throw error
      }
    }

    return composition
  }
}
