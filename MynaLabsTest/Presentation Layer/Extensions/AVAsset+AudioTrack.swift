import AVFoundation

/// Source: https://stackoverflow.com/a/42741683
extension AVAsset {

  func writeAudioTrack(
    to url: URL,
    completion: @escaping AudioEffectProcessorCompletion
  ) {
    do {
      let asset = try audioAsset()
      asset.write(to: url, completion: completion)
    } catch {
      completion(.failure(error))
    }
  }

  private func write(
    to url: URL,
    completion: @escaping AudioEffectProcessorCompletion
  ) {
    // delete old audio
    do {
      try FileManager.default.removeItem(at: url)
    } catch {
      completion(.failure(error))
    }

    guard let exportSession = AVAssetExportSession(
      asset: self,
      presetName: AVAssetExportPresetPassthrough
    ) else {
      let error = NSError(domain: "domain", code: -1, userInfo: ["Can't create AVAssetExportSession for AVAsset": description])
      completion(.failure(error))
      return
    }

    exportSession.outputFileType = .caf
    exportSession.outputURL = url

    exportSession.exportAsynchronously {
      switch exportSession.status {
        case .completed:
          completion(.success(url))
        default:
          let error = NSError(domain: "domain", code: -2, userInfo: ["Can't export audio track": url.description])
          completion(.failure(error))
      }
    }
  }

  private func audioAsset() throws -> AVAsset {
    let composition = AVMutableComposition()
    let audioTracks = tracks(withMediaType: .audio)

    for track in audioTracks {
      let compositionTrack = composition.addMutableTrack(
        withMediaType: .audio,
        preferredTrackID: kCMPersistentTrackID_Invalid
      )

      do {
        try compositionTrack?.insertTimeRange(
          track.timeRange,
          of: track,
          at: track.timeRange.start
        )
      } catch {
        throw error
      }
    }

    return composition
  }
}
