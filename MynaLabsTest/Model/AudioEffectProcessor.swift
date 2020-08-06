import AVFoundation

enum AudioEffectProcessorError: Error {

  case unknown

  var localizedDescription: String { "try_again".localized }
}

typealias AudioEffectProcessorCompletion = (Result<URL, Error>) -> Void

protocol AudioEffectProcessor {

  func apply(
    effect: MLTAudioEffect,
    toVideo url: URL,
    completion: @escaping AudioEffectProcessorCompletion
  )
}

class AudioEffectProcessorImpl: AudioEffectProcessor {

  private let queue = DispatchQueue(label: "AudioEffectProcessor")

  func apply(
    effect: MLTAudioEffect,
    toVideo url: URL,
    completion: @escaping AudioEffectProcessorCompletion
  ) {
    let videoUrl = url
    let videoAsset = AVAsset(url: videoUrl)
    guard let temporaryAudioDirectory = createTempDirectoryForAudio() else {
      completion(.failure(AudioEffectProcessorError.unknown))
      return
    }

    let merge: (URL, URL) -> Void = { videoUrl, audioUrl in
      self.mergeVideoAndAudio(videoUrl: videoUrl, audioUrl: audioUrl) { [weak self] result in
        self?.queue.async {
          switch result {
            case .success(let url):
              completion(.success(url))
            case .failure:
              completion(.failure(AudioEffectProcessorError.unknown))
          }
        }
      }
    }

    let audioEffect: (URL) -> Void = { url in
      self.applyAudioEffect(to: url, effect: effect) { result in
        switch result {
          case .success(let url):
            self.queue.async {
              merge(videoUrl, url)
            }
          case .failure(let error):
            completion(.failure(error))
        }
      }
    }

    queue.async {
      videoAsset.writeAudioTrack(to: temporaryAudioDirectory) { result in
        switch result {
          case .success(let url):
            audioEffect(url)
          case .failure(let error):
            completion(.failure(error))
        }
      }
    }
  }

  /// Source: https://developer.apple.com/documentation/avfoundation/audio_playback_recording_and_processing/avaudioengine/performing_offline_audio_processing
  private func applyAudioEffect(
    to url: URL,
    effect: MLTAudioEffect,
    completion: @escaping AudioEffectProcessorCompletion
  ) {
    let sourceFile: AVAudioFile
    let format: AVAudioFormat
    do {
      sourceFile = try AVAudioFile(forReading: url)
      format = sourceFile.processingFormat
    } catch {
      completion(.failure(error))
      return
    }

    let engine = AVAudioEngine()
    do {
      try engine.enableManualRenderingMode(
        .offline,
        format: sourceFile.processingFormat,
        maximumFrameCount: 1024
      )
    } catch {
      completion(.failure(error))
    }

    let player = AVAudioPlayerNode()
    let avEffect = avAudioEffect(for: effect)

    /// Stop the player node and engine.
    func stopOnError() {
      player.stop()
      engine.stop()
    }

    engine.attach(player)
    engine.attach(avEffect)

    engine.connect(player, to: avEffect, format: format)
    engine.connect(avEffect, to: engine.mainMixerNode, format: format)

    player.scheduleFile(sourceFile, at: nil)

    do {
      try engine.start()
      player.play()
    } catch {
      stopOnError()
      completion(.failure(error))
    }

    let outputFile: AVAudioFile
    do {
      let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let outputURL = documentsURL.appendingPathComponent("output.caf")
      outputFile = try AVAudioFile(forWriting: outputURL, settings: sourceFile.fileFormat.settings)
    } catch {
      stopOnError()
      completion(.failure(error))
      return
    }

    let buffer = AVAudioPCMBuffer(
      pcmFormat: engine.manualRenderingFormat,
      frameCapacity: engine.manualRenderingMaximumFrameCount
    )!

    while engine.manualRenderingSampleTime < sourceFile.length {
      do {
        let frameCount = sourceFile.length - engine.manualRenderingSampleTime
        let framesToRender = min(AVAudioFrameCount(frameCount), buffer.frameCapacity)

        let status = try engine.renderOffline(framesToRender, to: buffer)

        switch status {
          case .success:
            try outputFile.write(from: buffer)
          case .insufficientDataFromInputNode:
            // Applicable only when using the input node as one of the sources.
            break
          case .cannotDoInCurrentContext:
            // The engine couldn't render in the current render call.
            // Retry in the next iteration.
            break
          default:
            // An error occurred while rendering the audio.
            print("The manual rendering failed.")
            break
        }
      } catch {
        stopOnError()
        completion(.failure(error))
      }
    }

    stopOnError()
    completion(.success(outputFile.url))
  }

  private func avAudioEffect(for mltEffect: MLTAudioEffect) -> AVAudioUnitEffect {
    switch mltEffect {
      case .reverb:
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 50
        return reverb
      case .delay:
        let delay = AVAudioUnitDelay()
        delay.delayTime = 0.2
        delay.wetDryMix = 40
        return delay
      case .distortion:
        let distortion = AVAudioUnitDistortion()
        distortion.preGain = -10
        return distortion
    }
  }

  func mergeVideoAndAudio(
    videoUrl: URL,
    audioUrl: URL,
    completion: @escaping AudioEffectProcessorCompletion
  ) {

    let mixComposition = AVMutableComposition()
    var mutableCompositionVideoTrack = [AVMutableCompositionTrack]()
    var mutableCompositionAudioTrack = [AVMutableCompositionTrack]()

    let aVideoAsset = AVAsset(url: videoUrl)
    let aAudioAsset = AVAsset(url: audioUrl)

    let compositionAddVideo = mixComposition.addMutableTrack(
      withMediaType: .video,
      preferredTrackID: kCMPersistentTrackID_Invalid
    )!

    let compositionAddAudio = mixComposition.addMutableTrack(
      withMediaType: .audio,
      preferredTrackID: kCMPersistentTrackID_Invalid
    )!

    let aVideoAssetTrack: AVAssetTrack = aVideoAsset.tracks(withMediaType: AVMediaType.video)[0]
    let aAudioAssetTrack: AVAssetTrack = aAudioAsset.tracks(withMediaType: .audio)[0]


    //    if shouldFlipHorizontally {
    //      // Flip video horizontally
    //      var frontalTransform: CGAffineTransform = CGAffineTransform(scaleX: -1.0, y: 1.0)
    //      frontalTransform = frontalTransform.translatedBy(x: -aVideoAssetTrack.naturalSize.width, y: 0.0)
    //      frontalTransform = frontalTransform.translatedBy(x: 0.0, y: -aVideoAssetTrack.naturalSize.width)
    //      compositionAddVideo.preferredTransform = frontalTransform
    //    }

    mutableCompositionVideoTrack.append(compositionAddVideo)
    mutableCompositionAudioTrack.append(compositionAddAudio)

    do {
      try mutableCompositionVideoTrack[0].insertTimeRange(
        CMTimeRangeMake(start: CMTime.zero, duration: aVideoAssetTrack.timeRange.duration),
        of: aVideoAssetTrack,
        at: CMTime.zero
      )

      try mutableCompositionAudioTrack[0].insertTimeRange(
        CMTimeRangeMake(start: .zero, duration: aVideoAssetTrack.timeRange.duration),
        of: aAudioAssetTrack,
        at: .zero
      )
    } catch {
      completion(.failure(error))
    }

    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let savePathUrl = documentsURL.appendingPathComponent("output.mov")

    // delete old video
    do {
      try FileManager.default.removeItem(at: savePathUrl)
    } catch {
      print(error.localizedDescription)
    }

    let assetExport: AVAssetExportSession = AVAssetExportSession(
      asset: mixComposition,
      presetName: AVAssetExportPresetHighestQuality
    )!
    assetExport.outputFileType = .mov
    assetExport.outputURL = savePathUrl

    assetExport.exportAsynchronously {
      switch assetExport.status {
        case .completed:
          completion(.success(savePathUrl))
        default:
          completion(.failure(assetExport.error!))
      }
    }
  }

  private func createTempDirectoryForAudio() -> URL? {

    guard let tempDirURL = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("myTempFile.caf") else {
      return nil
    }

     // delete old audio
    do {
      try FileManager.default.removeItem(at: tempDirURL)
    } catch {
      print(error.localizedDescription)
    }

    do {
      try FileManager.default.createDirectory(
        at: tempDirURL,
        withIntermediateDirectories: true,
        attributes: nil
      )
    } catch {
      return nil
    }

    return tempDirURL
  }
}
